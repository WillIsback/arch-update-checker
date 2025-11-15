# Quick Start Guide

## 🚀 Installation (3 steps)

1. **Make the install script executable**:
   ```bash
   chmod +x install.sh
   ```

2. **Run the installer**:
   ```bash
   ./install.sh
   ```

3. **Add to PATH** (if needed):
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

## 📋 Daily Usage

### Quick Check
```bash
check-updates.sh
```

### View Last Report
```bash
ls -t ~/.local/share/update-reports/ | head -1 | xargs -I {} less ~/.local/share/update-reports/{}
```

### Update Packages
```bash
# Update everything
yay -Syu

# Or just official packages
sudo pacman -Syu
```

## ⚙️ Common Configurations

### Enable Boot Checks
```bash
systemctl --user enable update-check.service
```

### Enable Daily Checks
```bash
systemctl --user enable --now update-check.timer
```

### Check Status
```bash
systemctl --user status update-check.timer
journalctl --user -u update-check.service -n 20
```

## 🎯 VS Code Specific

The script will specifically track VS Code updates to help you maintain version synchronization between your Windows laptop and Linux desktop when working with remote servers.

**When you see a VS Code update notification:**
1. Update immediately: `yay -Syu`
2. Restart VS Code
3. Your remote connections will now use the updated version

## 📊 Understanding Reports

Reports include:
- ✅ Official repository updates
- ✅ AUR package updates  
- ✅ Critical package alerts (VS Code, kernel, etc.)
- ✅ Summary with update commands

## 🔧 Troubleshooting

**No notifications?**
```bash
sudo pacman -S libnotify
```

**Service not working?**
```bash
systemctl --user daemon-reload
systemctl --user restart update-check.service
```

**Want to change check frequency?**
Edit `~/.config/systemd/user/update-check.timer`

## 📚 Full Documentation

See README.md for complete documentation.

## 🎨 Integration with Hyprland

Add to your `~/.config/hypr/hyprland.conf`:
```
exec-once = ~/.local/bin/check-updates.sh --no-notify
```

This will check for updates on startup without showing notifications.
