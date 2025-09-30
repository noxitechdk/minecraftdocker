# GitHub Sync Manual Command Documentation

## 🚀 Manual GitHub Sync Command

After enabling GitHub sync, a manual sync script is automatically created that allows you to pull the latest changes from your GitHub repository while the server is running.

## 📋 Usage

### Command:
```bash
./github-sync.sh
```

### When to use:
- You've updated plugins or configs in your GitHub repository
- You want to sync changes without restarting the server
- You need to pull the latest version of configuration files

## 🔄 What the manual sync does:

### ✅ **Automatic Operations:**
1. **Pulls latest changes** from your GitHub repository
2. **Shows detailed information** about what files were updated
3. **Handles merge conflicts** automatically with backup
4. **Provides smart recommendations** for next steps

### 📝 **Example Output:**
```bash
github-sync~ Starting manual GitHub sync...
github-sync~ Pulling latest changes from repository...
github-sync~ Successfully pulled latest changes from repository
github-sync~ Files updated:
github-sync~ Plugin files updated - consider reloading plugins with '/reload' or '/plugman reload'
github-sync~ Configuration files updated - some changes may require server restart
github-sync~ Manual sync completed
```

## 🛠️ **Smart Recommendations:**

### **Plugin Updates (.jar files):**
- Suggests using `/reload` or `/plugman reload` commands
- Avoids need for full server restart when possible

### **Configuration Updates (.yml, .properties, etc.):**
- Warns when server restart might be needed
- Identifies which type of files were changed

### **Conflict Resolution:**
- Automatically backs up conflicting files
- Forces sync with remote repository
- Preserves your local changes in timestamped backup folders

## 🔧 **Error Handling:**

### **Common Issues:**
- **Authentication errors**: Check if GitHub token is valid
- **Network issues**: Verify internet connection
- **Repository not found**: Verify repository name and permissions
- **Merge conflicts**: Automatically resolved with backup

### **Error Logs:**
- Check `github-sync-errors.log` for detailed error information
- All operations are logged with timestamps

## 📋 **Prerequisites:**

1. **GitHub Sync must be enabled** (`GITHUB_SYNC_ENABLED=1`)
2. **Repository must be configured** (`GITHUB_SYNC_REPO`)
3. **Access token must be set** (`GITHUB_SYNC_TOKEN`)
4. **Server must have been started** at least once to initialize git

## 🎯 **Workflow Example:**

1. **Update your GitHub repository** with new plugins/configs
2. **Run manual sync** on your server: `./github-sync.sh`
3. **Follow recommendations** (reload plugins, restart if needed)
4. **Check logs** if any issues occur

## ⚠️ **Important Notes:**

- Manual sync only **pulls** from GitHub (no automatic push)
- Local changes are backed up before being overwritten
- Some configuration changes require server restart
- Plugin changes can often be applied with `/reload` command

## 🔍 **Troubleshooting:**

### Script not found:
- Ensure GitHub sync is enabled
- Restart server to create the script

### Permission denied:
```bash
chmod +x github-sync.sh
```

### Git not initialized:
- Restart server to initialize GitHub sync
- Check GitHub sync configuration