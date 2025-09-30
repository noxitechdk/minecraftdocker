# GitHub Sync Manual Commands Documentation

## 🚀 Manual GitHub Sync Commands

After enabling GitHub sync, two manual scripts are automatically created that allow you to sync with your GitHub repository while the server is running.

## 📋 Available Commands

### 1. **Pull from GitHub** (Download changes)
```bash
./github-sync.sh
```

### 2. **Push to GitHub** (Upload changes)
```bash
./github-push.sh [optional_commit_message]
```

## 🔽 Pull Command (github-sync.sh)

### **When to use:**
- You've updated plugins or configs in your GitHub repository
- You want to sync changes without restarting the server
- You need to pull the latest version of configuration files

### **What it does:**
1. **Pulls latest changes** from your GitHub repository
2. **Shows detailed information** about what files were updated
3. **Handles merge conflicts** automatically with backup
4. **Provides smart recommendations** for next steps

### **Example Output:**
```bash
github-sync~ Starting manual GitHub sync...
github-sync~ Pulling latest changes from repository...
github-sync~ Successfully pulled latest changes from repository
github-sync~ Files updated:
github-sync~ Plugin files updated - consider reloading plugins with '/reload'
github-sync~ Configuration files updated - some changes may require server restart
github-sync~ Manual sync completed
```

## 🔼 Push Command (github-push.sh)

### **When to use:**
- You've modified plugins or configs on the server
- You want to backup your current server configuration to GitHub
- You need to share your server setup with others

### **Usage Examples:**
```bash
# Push with default commit message
./github-push.sh

# Push with custom commit message
./github-push.sh "Updated server configs for new event"

# Push with detailed message
./github-push.sh "Added new plugins: WorldEdit, WorldGuard, EssentialsX"
```

### **What it does:**
1. **Adds only relevant files** (plugins, configs, world data)
2. **Shows what will be committed** before pushing
3. **Creates a commit** with timestamp or custom message
4. **Pushes to GitHub** with detailed error handling
5. **Provides clear feedback** about success or failure

### **Example Output:**
```bash
github-push~ Starting manual GitHub push...
github-push~ Adding files to git...
github-push~ Files to be committed:
github-push~   + plugins/newplugin.jar
github-push~   + server.properties
github-push~   + config/paper-global.yml
github-push~ Committing changes with message: 'Updated server configuration'
github-push~ Successfully committed changes
github-push~ Pushing to remote repository...
github-push~ Successfully pushed changes to GitHub repository
github-push~ Your server configs and plugins are now synced to GitHub
github-push~ Manual push completed successfully
```

## 🛠️ **Smart Features:**

### **🔍 Intelligent File Detection:**
- **Pull**: Plugin updates suggest `/reload`, config updates warn about restart
- **Push**: Only commits relevant files (plugins, configs, world data)
- **Both**: Show exactly which files were changed

### **🛡️ Advanced Error Handling:**
- **Authentication errors**: Clear token validation messages
- **Network issues**: Specific connectivity troubleshooting
- **Merge conflicts**: Automatic backup and resolution
- **Push rejections**: Suggests pulling first

### **📊 Detailed Feedback:**
- **File-by-file** change reporting
- **Smart recommendations** for next steps
- **Clear success/failure** indicators
- **Actionable error messages**

## 🎯 **Common Workflows:**

### **Scenario 1: Update from GitHub**
1. **Edit configs** in GitHub repository
2. **Run**: `./github-sync.sh`
3. **Follow suggestions**: `/reload` or restart server

### **Scenario 2: Backup to GitHub**
1. **Configure server** with new plugins/settings
2. **Run**: `./github-push.sh "New server setup"`
3. **Verify**: Check GitHub repository for changes

### **Scenario 3: Collaborate with team**
1. **Team member** pushes changes to GitHub
2. **You run**: `./github-sync.sh`
3. **Apply changes**: Reload plugins or restart as needed
4. **Make your changes** and push back with `./github-push.sh`

## ⚠️ **Important Notes:**

### **File Scope:**
- **Included**: plugins/, config/, *.properties, *.yml, *.yaml, *.toml, world data
- **Excluded**: server.jar, logs/, cache/, player data (ops.json, etc.)

### **Safety Features:**
- **Local backups** before overwriting files
- **Commit before push** - changes are saved locally even if push fails
- **Detailed logging** in `github-sync-errors.log`

### **Performance:**
- **No downtime** required for most operations
- **Plugin reload** often sufficient instead of restart
- **Minimal network usage** - only syncs changed files

## 🔧 **Troubleshooting:**

### **Scripts not found:**
```bash
# Ensure GitHub sync is enabled and restart server
# Scripts are created automatically on startup
```

### **Permission denied:**
```bash
chmod +x github-sync.sh github-push.sh
```

### **Push rejected:**
```bash
# Pull latest changes first
./github-sync.sh
# Then try push again
./github-push.sh
```

### **Authentication failed:**
- Check GitHub token permissions
- Verify token hasn't expired
- Ensure token has repository write access (for push)

## 🔍 **Debug Information:**
- Check `github-sync-errors.log` for detailed error logs
- Verify repository configuration with `git remote -v`
- Test connectivity with `git ls-remote origin`