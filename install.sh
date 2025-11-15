#!/bin/bash

# Installation script for Package Update Checker
# Run this script to install and configure the update checker

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

echo -e "${BOLD}${BLUE}Package Update Checker Installation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running on Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    echo -e "${RED}Error: This script is designed for Arch Linux${NC}"
    exit 1
fi

# Check for required tools
echo "Checking prerequisites..."

missing_tools=()

if ! command -v checkupdates &> /dev/null; then
    missing_tools+=("pacman-contrib")
fi

if ! command -v notify-send &> /dev/null; then
    echo -e "${YELLOW}⚠ notify-send not found. Desktop notifications will be disabled.${NC}"
    echo "  Install libnotify for notifications: sudo pacman -S libnotify"
fi

# Check for AUR helper
aur_helper=""
if command -v yay &> /dev/null; then
    aur_helper="yay"
elif command -v paru &> /dev/null; then
    aur_helper="paru"
else
    echo -e "${YELLOW}⚠ No AUR helper found (yay or paru)${NC}"
    echo "  AUR package checking will not be available"
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install missing tools
if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Installing missing tools: ${missing_tools[*]}${NC}"
    sudo pacman -S --needed "${missing_tools[@]}"
fi

echo -e "${GREEN}✓ Prerequisites checked${NC}"
echo ""

# Create directories
echo "Creating directories..."
mkdir -p ~/.local/bin
mkdir -p ~/.config/systemd/user
mkdir -p ~/.local/share/update-reports
mkdir -p ~/.cache/update-checker

echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Install the main script
echo "Installing update checker script..."
if [[ -f check-updates.sh ]]; then
    cp check-updates.sh ~/.local/bin/check-updates.sh
    chmod +x ~/.local/bin/check-updates.sh
    echo -e "${GREEN}✓ Script installed to ~/.local/bin/check-updates.sh${NC}"
else
    echo -e "${RED}Error: check-updates.sh not found in current directory${NC}"
    exit 1
fi
echo ""

# Install systemd service and timer
echo "Installing systemd service..."
if [[ -f update-check.service ]]; then
    cp update-check.service ~/.config/systemd/user/
    echo -e "${GREEN}✓ Service file installed${NC}"
else
    echo -e "${YELLOW}⚠ update-check.service not found. Skipping service installation.${NC}"
fi

if [[ -f update-check.timer ]]; then
    cp update-check.timer ~/.config/systemd/user/
    echo -e "${GREEN}✓ Timer file installed${NC}"
else
    echo -e "${YELLOW}⚠ update-check.timer not found. Skipping timer installation.${NC}"
fi
echo ""

# Reload systemd
echo "Reloading systemd user daemon..."
systemctl --user daemon-reload
echo -e "${GREEN}✓ Systemd daemon reloaded${NC}"
echo ""

# Ask about enabling services
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Configuration Options:"
echo ""
echo "1. Enable update check on boot"
echo "2. Enable daily update checks (via timer)"
echo "3. Both"
echo "4. Neither (manual installation)"
echo ""
read -p "Select option [1-4]: " -n 1 -r option
echo
echo ""

case $option in
    1)
        systemctl --user enable update-check.service
        echo -e "${GREEN}✓ Boot check enabled${NC}"
        echo "  The update checker will run on next boot"
        ;;
    2)
        systemctl --user enable --now update-check.timer
        echo -e "${GREEN}✓ Daily timer enabled and started${NC}"
        echo "  Updates will be checked daily"
        ;;
    3)
        systemctl --user enable update-check.service
        systemctl --user enable --now update-check.timer
        echo -e "${GREEN}✓ Boot check and daily timer enabled${NC}"
        echo "  Updates will be checked on boot and daily"
        ;;
    4)
        echo "Services not enabled. You can enable them manually:"
        echo "  Boot check: systemctl --user enable update-check.service"
        echo "  Daily timer: systemctl --user enable --now update-check.timer"
        ;;
    *)
        echo -e "${YELLOW}Invalid option. Services not enabled.${NC}"
        ;;
esac
echo ""

# Test run
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Would you like to run a test check now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Running test check..."
    echo ""
    ~/.local/bin/check-updates.sh
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}${GREEN}Installation Complete!${NC}"
echo ""
echo "Usage:"
echo "  Manual check:        ~/.local/bin/check-updates.sh"
echo "  Brief report:        ~/.local/bin/check-updates.sh --brief"
echo "  No notifications:    ~/.local/bin/check-updates.sh --no-notify"
echo "  Help:                ~/.local/bin/check-updates.sh --help"
echo ""
echo "Service management:"
echo "  Check timer status:  systemctl --user status update-check.timer"
echo "  Check service logs:  journalctl --user -u update-check.service"
echo "  Disable timer:       systemctl --user disable --now update-check.timer"
echo ""
echo "Reports are saved in: ~/.local/share/update-reports/"
echo ""
echo -e "${YELLOW}Note:${NC} Make sure ~/.local/bin is in your PATH"
echo "Add to your ~/.bashrc or ~/.zshrc:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
