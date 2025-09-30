#!/bin/bash

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# check if LOG_PREFIX is set
if [ -z "$LOG_PREFIX" ]; then
	LOG_PREFIX="\033[1m\033[33minstall~\033[0m"
fi

# Switch to the container's working directory
cd /home/container || exit 1

# Print Java version
printf "${LOG_PREFIX} java -version\n"
java -version

JAVA_MAJOR_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')

if [[ "$MALWARE_SCAN" == "1" ]]; then
	if [[ ! -f "/MCAntiMalware.jar" ]]; then
		echo -e "${LOG_PREFIX} Malware scanning is only available for Java 17 and above, skipping..."
	else
		echo -e "${LOG_PREFIX} Scanning for malware... (This may take a while)"

		java -jar /MCAntiMalware.jar --scanDirectory . --singleScan true --disableAutoUpdate true

		if [ $? -eq 0 ]; then
			echo -e "${LOG_PREFIX} Malware scan has passed"
		else
			echo -e "${LOG_PREFIX} Malware scan has failed"
			exit 1
		fi
	fi
else
	echo -e "${LOG_PREFIX} Skipping malware scan..."
fi

if [[ -n "${GITHUB_SYNC_REPO}" && -n "${GITHUB_SYNC_TOKEN}" ]]; then
	echo -e "${LOG_PREFIX} GitHub Sync enabled - Setting up repository sync..."

	git config --global user.name "${GITHUB_SYNC_USERNAME:-minecraft-server}"
	git config --global user.email "${GITHUB_SYNC_EMAIL:-server@minecraft.com}"
	git config --global init.defaultBranch main

	if [[ ! -d ".git" ]]; then
		echo -e "${LOG_PREFIX} Initializing GitHub sync repository..."

		if git clone "https://${GITHUB_SYNC_TOKEN}@github.com/${GITHUB_SYNC_REPO}.git" /tmp/sync-repo 2>/dev/null; then
			echo -e "${LOG_PREFIX} Repository found, syncing existing data..."

			if [[ -d "/tmp/sync-repo/plugins" ]]; then
				mkdir -p plugins
				cp -r /tmp/sync-repo/plugins/* plugins/ 2>/dev/null || true
				echo -e "${LOG_PREFIX} Synced plugins from repository"
			fi

			for config_file in server.properties spigot.yml bukkit.yml paper.yml config.yml settings.yml velocity.toml; do
				if [[ -f "/tmp/sync-repo/$config_file" ]]; then
					cp "/tmp/sync-repo/$config_file" "./$config_file"
					echo -e "${LOG_PREFIX} Synced $config_file from repository"
				fi
			done

			for config_dir in config world world_nether world_the_end; do
				if [[ -d "/tmp/sync-repo/$config_dir" ]]; then
					cp -r "/tmp/sync-repo/$config_dir" "./" 2>/dev/null || true
					echo -e "${LOG_PREFIX} Synced $config_dir from repository"
				fi
			done

			git init
			git remote add origin "https://${GITHUB_SYNC_TOKEN}@github.com/${GITHUB_SYNC_REPO}.git"

			rm -rf /tmp/sync-repo
		else
			echo -e "${LOG_PREFIX} Repository not found, will create initial sync later..."
			git init
			git remote add origin "https://${GITHUB_SYNC_TOKEN}@github.com/${GITHUB_SYNC_REPO}.git"
		fi

		cat > .gitignore << 'EOF'
# Server files to ignore
*.jar
*.log
logs/
cache/
crash-reports/
libraries/
versions/
banned-*.json
ops.json
whitelist.json
usernamecache.json
usercache.json
session.lock
*.pid
temp/
.console_history

# Keep only plugins and configs
!plugins/
!*.properties
!*.yml
!*.yaml
!*.toml
!config/
!world/
!world_nether/
!world_the_end/
EOF

		echo -e "${LOG_PREFIX} GitHub sync repository initialized"
	else
		echo -e "${LOG_PREFIX} Git repository already exists, pulling latest changes..."
		git pull origin main 2>/dev/null || echo -e "${LOG_PREFIX} Pull failed or first time setup"
	fi

	(
		while true; do
			sleep 600

			git add plugins/ *.properties *.yml *.yaml *.toml config/ world/ world_nether/ world_the_end/ 2>/dev/null || true
			
			if ! git diff --cached --quiet 2>/dev/null; then
				git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S UTC')" 2>/dev/null
				
				if git push origin main 2>/dev/null; then
					echo "$(date '+%Y-%m-%d %H:%M:%S') - GitHub sync: Changes pushed successfully" >> sync.log
				else
					echo "$(date '+%Y-%m-%d %H:%M:%S') - GitHub sync: Push failed" >> sync.log
				fi
			else
				echo "$(date '+%Y-%m-%d %H:%M:%S') - GitHub sync: No changes to sync" >> sync.log
			fi
		done
	) &
	
	echo -e "${LOG_PREFIX} GitHub sync background process started (10-minute intervals)"
else
	echo -e "${LOG_PREFIX} GitHub sync disabled (GITHUB_SYNC_REPO not configured)"
fi

# Auto-install Hibernate plugin (only if enabled)
if [[ "${HIBERNATE_ENABLED:-1}" == "1" ]]; then
	echo -e "${LOG_PREFIX} Installing Hibernate plugin..."

	mkdir -p plugins

	HIBERNATE_INSTALLED=false

	if [[ -f "/hibernatesystem.jar" ]]; then
		echo -e "${LOG_PREFIX} Found static Hibernate plugin, installing..."
		cp /hibernatesystem.jar plugins/hibernatesystem.jar
		HIBERNATE_INSTALLED=true
	fi

	echo -e "${LOG_PREFIX} Checking for latest Hibernate version from GitHub..."

	LATEST_URL=$(curl -s "https://api.github.com/repos/noxitechdk/Hibernate/releases/latest" | grep "browser_download_url.*\.jar" | head -n 1 | cut -d '"' -f 4)

	if [[ -n "$LATEST_URL" ]]; then
		echo -e "${LOG_PREFIX} Downloading latest Hibernate plugin from: $LATEST_URL"

		if curl -sL "$LATEST_URL" -o /tmp/hibernate-latest.jar; then
			mv /tmp/hibernate-latest.jar plugins/hibernatesystem.jar
			echo -e "${LOG_PREFIX} Latest Hibernate plugin installed successfully"
			HIBERNATE_INSTALLED=true
		else
			echo -e "${LOG_PREFIX} Failed to download latest version, using static version if available"
		fi
	else
		echo -e "${LOG_PREFIX} Could not fetch latest release info, using static version if available"
	fi

	if [[ "$HIBERNATE_INSTALLED" == "true" ]]; then
		echo -e "${LOG_PREFIX} Hibernate plugin installation completed"
	else
		echo -e "${LOG_PREFIX} No Hibernate plugin found to install"
	fi
else
	echo -e "${LOG_PREFIX} Hibernate plugin installation disabled (HIBERNATE_ENABLED=0)"
fi

if [[ "$AUTOMATIC_UPDATING" == "1" ]]; then
	if [[ "$SERVER_JARFILE" == "server.jar" ]]; then
		printf "${LOG_PREFIX} Checking for updates...\n"

		# Check if libraries/net/minecraftforge/forge exists
		if [ -d "libraries/net/minecraftforge/forge" ] && [ -z "${HASH}" ]; then
			# get first folder in libraries/net/minecraftforge/forge
			FORGE_VERSION=$(ls libraries/net/minecraftforge/forge | head -n 1)

			# Check if -server.jar or -universal.jar exists in libraries/net/minecraftforge/forge/${FORGE_VERSION}
			FILES=$(ls libraries/net/minecraftforge/forge/${FORGE_VERSION} | grep -E "(-server.jar|-universal.jar)")

			# Check if there are any files
			if [ -n "${FILES}" ]; then
				# get first file in libraries/net/minecraftforge/forge/${FORGE_VERSION}
				FILE=$(echo "${FILES}" | head -n 1)

				# Hash file
				HASH=$(sha256sum libraries/net/minecraftforge/forge/${FORGE_VERSION}/${FILE} | awk '{print $1}')
			fi
		fi

		# Check if libraries/net/neoforged/neoforge folder exists
		if [ -d "libraries/net/neoforged/neoforge" ] && [ -z "${HASH}" ]; then
			# get first folder in libraries/net/neoforged/neoforge
			NEOFORGE_VERSION=$(ls libraries/net/neoforged/neoforge | head -n 1)

			# Check if -server.jar or -universal.jar exists in libraries/net/neoforged/neoforge/${NEOFORGE_VERSION}
			FILES=$(ls libraries/net/neoforged/neoforge/${NEOFORGE_VERSION} | grep -E "(-server.jar|-universal.jar)")

			# Check if there are any files
			if [ -n "${FILES}" ]; then
				# get first file in libraries/net/neoforged/neoforge/${NEOFORGE_VERSION}
				FILE=$(echo "${FILES}" | head -n 1)

				# Hash file
				HASH=$(sha256sum libraries/net/neoforged/neoforge/${NEOFORGE_VERSION}/${FILE} | awk '{print $1}')
			fi
		fi

		# Hash server jar file
		if [ -z "${HASH}" ]; then
			HASH=$(sha256sum $SERVER_JARFILE | awk '{print $1}')
		fi

		# Check if hash is set
		if [ -n "${HASH}" ]; then
			API_RESPONSE=$(curl --connect-timeout 4 -s "https://mcjars.app/api/v1/build/$HASH")

			# Check if .success is true
			if [ "$(echo $API_RESPONSE | jq -r '.success')" = "true" ]; then
				if [ "$(echo $API_RESPONSE | jq -r '.build.id')" != "$(echo $API_RESPONSE | jq -r '.latest.id')" ]; then
					echo -e "${LOG_PREFIX} New build found. Updating server..."

					BUILD_ID=$(echo $API_RESPONSE | jq -r '.latest.id')
					bash <(curl -s "https://mcjars.app/api/v1/script/$BUILD_ID/bash?echo=false")

					echo -e "${LOG_PREFIX} Server has been updated"
				else
					echo -e "${LOG_PREFIX} Server is up to date"
				fi
			else
				echo -e "${LOG_PREFIX} Could not check for updates. Skipping update check."
			fi
		else
			echo -e "${LOG_PREFIX} Could not find hash. Skipping update check."
		fi
	else
		echo -e "${LOG_PREFIX} Automatic updating is enabled, but the server jar file is not server.jar. Skipping update check."
	fi
fi

# check if libraries/net/minecraftforge/forge exists and the SERVER_JARFILE file does not exist
if [ -d "libraries/net/minecraftforge/forge" ] && [ ! -f "$SERVER_JARFILE" ]; then
	echo -e "${LOG_PREFIX} Downloading Forge server jar file..."
	curl -s https://s3.mcjars.app/forge/ForgeServerJAR.jar -o $SERVER_JARFILE

	echo -e "${LOG_PREFIX} Forge server jar file has been downloaded"
fi

# check if libraries/net/neoforged/neoforge exists and the SERVER_JARFILE file does not exist
if [ -d "libraries/net/neoforged/neoforge" ] && [ ! -f "$SERVER_JARFILE" ]; then
	echo -e "${LOG_PREFIX} Downloading NeoForge server jar file..."
	curl -s https://s3.mcjars.app/neoforge/NeoForgeServerJAR.jar -o $SERVER_JARFILE

	echo -e "${LOG_PREFIX} NeoForge server jar file has been downloaded"
fi

# check if libraries/net/neoforged/forge exists and the SERVER_JARFILE file does not exist
if [ -d "libraries/net/neoforged/forge" ] && [ ! -f "$SERVER_JARFILE" ]; then
	echo -e "${LOG_PREFIX} Downloading NeoForge server jar file..."
	curl -s https://s3.mcjars.app/neoforge/NeoForgeServerJAR.jar -o $SERVER_JARFILE

	echo -e "${LOG_PREFIX} NeoForge server jar file has been downloaded"
fi

# server.properties
if [ -f "eula.txt" ]; then
	# create server.properties
	touch server.properties
fi

if [ -f "server.properties" ]; then
	# set server-ip to 0.0.0.0
	if grep -q "server-ip=" server.properties; then
		sed -i 's/server-ip=.*/server-ip=0.0.0.0/' server.properties
	else
		echo "server-ip=0.0.0.0" >> server.properties
	fi

	# set server-port to SERVER_PORT
	if grep -q "server-port=" server.properties; then
		sed -i "s/server-port=.*/server-port=${SERVER_PORT}/" server.properties
	else
		echo "server-port=${SERVER_PORT}" >> server.properties
	fi

	# set query.enabled to true
	if grep -q "query.enabled=" server.properties; then
		sed -i "s/query.enabled=.*/query.enabled=true/" server.properties
	else
		echo "query.enabled=true" >> server.properties
	fi

	# set query.port to SERVER_PORT
	if grep -q "query.port=" server.properties; then
		sed -i "s/query.port=.*/query.port=${SERVER_PORT}/" server.properties
	else
		echo "query.port=${SERVER_PORT}" >> server.properties
	fi
fi

# settings.yml
if [ -f "settings.yml" ]; then
	# set ip to 0.0.0.0
	if grep -q "ip" settings.yml; then
		sed -i "s/ip: .*/ip: '0.0.0.0'/" settings.yml
	fi

	# set port to SERVER_PORT
	if grep -q "port" settings.yml; then
		sed -i "s/port: .*/port: ${SERVER_PORT}/" settings.yml
	fi
fi

# velocity.toml
if [ -f "velocity.toml" ]; then
	# set bind to 0.0.0.0:SERVER_PORT
	if grep -q "bind" velocity.toml; then
		sed -i "s/bind = .*/bind = \"0.0.0.0:${SERVER_PORT}\"/" velocity.toml
	else
		echo "bind = \"0.0.0.0:${SERVER_PORT}\"" >> velocity.toml
	fi
fi

# config.yml
if [ -f "config.yml" ]; then
	# set query_port to SERVER_PORT
	if grep -q "query_port" config.yml; then
		sed -i "s/query_port: .*/query_port: ${SERVER_PORT}/" config.yml
	else
		echo "query_port: ${SERVER_PORT}" >> config.yml
	fi

	# set host to 0.0.0.0:SERVER_PORT
	if grep -q "host" config.yml; then
		sed -i "s/host: .*/host: 0.0.0.0:${SERVER_PORT}/" config.yml
	else
		echo "host: 0.0.0.0:${SERVER_PORT}" >> config.yml
	fi
fi

if [[ "$OVERRIDE_STARTUP" == "1" ]]; then
	FLAGS=("-Dterminal.jline=false -Dterminal.ansi=true")

	# SIMD Operations are only for Java 16 - 21
	if [[ "$SIMD_OPERATIONS" == "1" ]]; then
		if [[ "$JAVA_MAJOR_VERSION" -ge 16 ]] && [[ "$JAVA_MAJOR_VERSION" -le 21 ]]; then
			FLAGS+=("--add-modules=jdk.incubator.vector")
		else
			echo -e "${LOG_PREFIX} SIMD Operations are only available for Java 16 - 21, skipping..."
		fi
	fi

	if [[ "$REMOVE_UPDATE_WARNING" == "1" ]]; then
		FLAGS+=("-DIReallyKnowWhatIAmDoingISwear")
	fi

	if [[ -n "$JAVA_AGENT" ]]; then
		if [ -f "$JAVA_AGENT" ]; then
			FLAGS+=("-javaagent:$JAVA_AGENT")
		else
			echo -e "${LOG_PREFIX} JAVA_AGENT file does not exist, skipping..."
		fi
	fi

	if [[ "$ADDITIONAL_FLAGS" == "Aikar's Flags" ]]; then
		FLAGS+=("-XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true")
	elif [[ "$ADDITIONAL_FLAGS" == "Velocity Flags" ]]; then
		FLAGS+=("-XX:+ParallelRefProcEnabled -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=4M -XX:MaxInlineLevel=15")
	fi

	if [[ "$MINEHUT_SUPPORT" == "Velocity" ]]; then
		FLAGS+=("-Dmojang.sessionserver=https://api.minehut.com/mitm/proxy/session/minecraft/hasJoined")
	elif [[ "$MINEHUT_SUPPORT" == "Waterfall" ]]; then
		FLAGS+=("-Dwaterfall.auth.url=\"https://api.minehut.com/mitm/proxy/session/minecraft/hasJoined?username=%s&serverId=%s%s\")")
	elif [[ "$MINEHUT_SUPPORT" = "Bukkit" ]]; then
		FLAGS+=("-Dminecraft.api.auth.host=https://authserver.mojang.com/ -Dminecraft.api.account.host=https://api.mojang.com/ -Dminecraft.api.services.host=https://api.minecraftservices.com/ -Dminecraft.api.session.host=https://api.minehut.com/mitm/proxy")
	fi

	SERVER_MEMORY_REAL=$(($SERVER_MEMORY*$MAXIMUM_RAM/100))
	PARSED="java ${FLAGS[*]} -Xms256M -Xmx${SERVER_MEMORY_REAL}M -jar ${SERVER_JARFILE} nogui"

	# Display the command we're running in the output, and then execute it with the env
	# from the container itself.
	printf "${LOG_PREFIX} %s\n" "$PARSED"
	# shellcheck disable=SC2086
	exec env ${PARSED}
else
	# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
	# variable format of "${VARIABLE}" before evaluating the string and automatically
	# replacing the values.
	PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

	# Display the command we're running in the output, and then execute it with the env
	# from the container itself.
	printf "${LOG_PREFIX} %s\n" "$PARSED"
	# shellcheck disable=SC2086
	exec env ${PARSED}
fi