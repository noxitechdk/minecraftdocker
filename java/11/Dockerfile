FROM        --platform=$TARGETOS/$TARGETARCH eclipse-temurin:11-jdk-focal

LABEL       author="Robert Jansen" maintainer="NuXiCloud"

LABEL       org.opencontainers.image.source="https://github.com/noxitechdk/minecraftdocker"
LABEL       org.opencontainers.image.licenses=MIT

RUN         rm -rf /usr/bin/dd \
						&& rm -rf /usr/bin/fallocate \
						&& rm -rf /usr/bin/truncate \
						&& rm -rf /usr/bin/xfs_mkfile

RUN         apt-get update -y \
						&& apt-get install -y curl

RUN         curl -sSL http://noxitech.dk/install/hibernate-1.0-SNAPSHOT \
						-o /hibernate-1.0-SNAPSHOT

RUN 		apt-get install -y jq unzip lsof ca-certificates openssl git tar sqlite3 fontconfig libfreetype6 tzdata iproute2 libstdc++6 \
						&& useradd -d /home/container -m container

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./../entrypoint.sh /entrypoint.sh
CMD         [ "/bin/bash", "/entrypoint.sh" ]
