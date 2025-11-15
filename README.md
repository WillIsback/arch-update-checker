# Arch Linux Package Update Checker

A comprehensive script for Arch Linux that automatically checks for package updates and generates formatted reports with changelogs and repository information.

## Features

- 📦 **Comprehensive Update Detection**: Checks both official repositories and AUR packages
- 📊 **Detailed Reports**: Formatted reports with package information, versions, and changelogs
- 🔔 **Desktop Notifications**: Optional notifications for available updates
- 🎯 **Critical Package Tracking**: Special attention to important packages like VS Code
- ⏰ **Automated Scheduling**: Run on boot or at scheduled intervals via systemd
- 📝 **Report History**: All reports saved with timestamps for reference

## Use Case

This tool was created to solve the problem of VS Code synchronization between Windows and Linux systems when working with remote servers. When VS Code on Windows auto-updates but the Linux installation doesn't, it can cause issues with extensions like GitHub Copilot that require version matching.

## Prerequisites

- Arch Linux (or Arch-based distribution)
- `pacman-contrib` package (provides `checkupdates`)
- AUR helper: `yay` or `paru` (for AUR package support)
- `libnotify` (optional, for desktop notifications)

## Installation

1. **Download the files**:
   ```bash
   # If you have the files in a directory, navigate there
   cd /path/to/update-checker
   ```

2. **Make the install script executable**:
   ```bash
   chmod +x install.sh
   ```

3. **Run the installation**:
   ```bash
   ./install.sh
   ```

4. **Add ~/.local/bin to your PATH** (if not already done):
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

## Usage

### Manual Checks

```bash
# Full detailed check with notifications
check-updates.sh

# Brief output without changelogs
check-updates.sh --brief

# No desktop notifications
check-updates.sh --no-notify

# Skip changelog information
check-updates.sh --no-changelog

# Specify AUR helper
check-updates.sh --aur-helper paru

# Show help
check-updates.sh --help
```

### Automated Checks

The script can run automatically via systemd:

#### On Boot:
```bash
# Enable boot check
systemctl --user enable update-check.service

# Disable boot check
systemctl --user disable update-check.service
```

#### Daily Scheduled Checks:
```bash
# Enable daily checks at a specific time
systemctl --user enable --now update-check.timer

# Check timer status
systemctl --user status update-check.timer

# Disable daily checks
systemctl --user disable --now update-check.timer
```

### Viewing Reports

Reports are saved in `~/.local/share/update-reports/` with timestamps:

```bash
# View latest report
cat ~/.local/share/update-reports/update-report-*.txt | tail -1

# List all reports
ls -lh ~/.local/share/update-reports/

# View a specific report
less ~/.local/share/update-reports/update-report-20241115-093000.txt
```

### Checking Service Logs

```bash
# View recent logs
journalctl --user -u update-check.service -n 50

# Follow logs in real-time
journalctl --user -u update-check.service -f
```

## Report Format

The script generates reports with the following sections:

1. **Official Repository Updates**
   - Package name
   - Current and new versions
   - Repository source
   - Description
   - Download size
   - Changelog information

2. **AUR Package Updates**
   - Package name
   - Current and new versions
   - Description
   - AUR URL
   - Changelog information

3. **Critical Package Status**
   - Special section for important packages (VS Code, kernel, etc.)
   - Highlights packages that need immediate attention

4. **Summary**
   - Total update count
   - Breakdown by repository type
   - Update commands

## Example Report

```
╔════════════════════════════════════════════════════════════════════════════╗
║                    ARCH LINUX PACKAGE UPDATE REPORT                        ║
╚════════════════════════════════════════════════════════════════════════════╝

Generated: 2024-11-15 09:30:00
Hostname: myarchbox

═══════════════════════════════════════════════════════════════════════════
  OFFICIAL REPOSITORY UPDATES
═══════════════════════════════════════════════════════════════════════════

📦 3 official package(s) available for update:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Package: firefox
  Current Version:  120.0-1
  New Version:      121.0-1
  Repository:       extra
  Description:      Standalone web browser from mozilla.org
  Download Size:    60.4 MiB

...
```

## Configuration

### Customizing Critical Packages

Edit the script to add your own critical packages:

```bash
# In check-updates.sh, find this line:
local critical_packages=("code" "visual-studio-code-bin" "linux" "linux-lts")

# Add your packages:
local critical_packages=("code" "visual-studio-code-bin" "linux" "linux-lts" "docker" "nvidia")
```

### Changing Check Frequency

Edit the timer file to change when checks run:

```bash
# Edit the timer
nano ~/.config/systemd/user/update-check.timer

# Change OnCalendar value:
OnCalendar=daily          # Every day
OnCalendar=weekly         # Every week
OnCalendar=Mon *-*-* 09:00:00  # Every Monday at 9 AM

# Reload systemd after changes
systemctl --user daemon-reload
systemctl --user restart update-check.timer
```

## Troubleshooting

### No Updates Showing

```bash
# Manually sync databases
sudo pacman -Sy

# Check if checkupdates works
checkupdates

# Check AUR helper
yay -Qua
```

### Notifications Not Working

```bash
# Install libnotify if missing
sudo pacman -S libnotify

# Test notification
notify-send "Test" "This is a test notification"
```

### Service Not Running

```bash
# Check service status
systemctl --user status update-check.service

# Check for errors
journalctl --user -u update-check.service -n 50

# Reload daemon after changes
systemctl --user daemon-reload
```

### Permission Issues

```bash
# Ensure script is executable
chmod +x ~/.local/bin/check-updates.sh

# Check file ownership
ls -l ~/.local/bin/check-updates.sh
```

## VS Code Synchronization

To keep VS Code synchronized between your Windows laptop and Linux desktop:

1. **Enable auto-check on boot**: This ensures you're notified of VS Code updates
2. **Update promptly**: Run `yay -Syu` when VS Code updates are available
3. **Monitor critical packages**: The script specifically tracks VS Code packages

### Remote Development Setup

If you're using VS Code Remote SSH:

1. The local VS Code version determines the remote server version
2. Keep your local installations synchronized
3. If you get Copilot warnings, ensure both Windows and Linux have matching versions

## Uninstallation

```bash
# Disable and remove services
systemctl --user disable --now update-check.service update-check.timer
rm ~/.config/systemd/user/update-check.{service,timer}
systemctl --user daemon-reload

# Remove script and directories
rm ~/.local/bin/check-updates.sh
rm -rf ~/.local/share/update-reports
rm -rf ~/.cache/update-checker
```

## Advanced Usage

### Integration with Other Tools

#### Add to Hyprland startup:
```bash
# In ~/.config/hypr/hyprland.conf
exec-once = ~/.local/bin/check-updates.sh --no-notify
```

#### Create a waybar module:
```json
"custom/updates": {
    "exec": "checkupdates | wc -l",
    "interval": 3600,
    "format": "📦 {}",
    "on-click": "~/.local/bin/check-updates.sh"
}
```

#### Email reports:
```bash
# Install mailutils and configure
# Then modify the script to email reports:
cat "${REPORT_FILE}" | mail -s "Update Report" your@email.com
```

## Contributing

Feel free to customize the script for your needs. Common modifications:

- Add more critical packages
- Change report formatting
- Add email notifications
- Integrate with other notification systems
- Add package filtering

## License

This script is free to use and modify for personal use.

## Support

For issues, questions, or suggestions, please refer to the Arch Linux wiki or community forums:
- https://wiki.archlinux.org/
- https://bbs.archlinux.org/

## Related Resources

- [Arch Linux Package Management](https://wiki.archlinux.org/title/Pacman)
- [AUR Helpers](https://wiki.archlinux.org/title/AUR_helpers)
- [Systemd/User](https://wiki.archlinux.org/title/Systemd/User)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
