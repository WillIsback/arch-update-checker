#!/bin/bash

# Package Update Report Script for Arch Linux
# Provides formatted reports with changelogs and repository information

set -euo pipefail

# Color definitions for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Configuration
readonly REPORT_DIR="${HOME}/.local/share/update-reports"
readonly REPORT_FILE="${REPORT_DIR}/update-report-$(date +%Y%m%d-%H%M%S).txt"
readonly CACHE_DIR="${HOME}/.cache/update-checker"
readonly LAST_CHECK_FILE="${CACHE_DIR}/last-check"

# Notification settings
NOTIFY=true
DETAILED=true
SHOW_CHANGELOG=true
AUR_HELPER="yay" # can be yay or paru

# Global arrays to track updates
declare -a CRITICAL_UPDATES_OFFICIAL=()
declare -a CRITICAL_UPDATES_AUR=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-notify)
            NOTIFY=false
            shift
            ;;
        --brief)
            DETAILED=false
            SHOW_CHANGELOG=false
            shift
            ;;
        --no-changelog)
            SHOW_CHANGELOG=false
            shift
            ;;
        --aur-helper)
            AUR_HELPER="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --no-notify      Don't send desktop notifications"
            echo "  --brief          Brief output without details"
            echo "  --no-changelog   Skip changelog information"
            echo "  --aur-helper     Specify AUR helper (yay or paru, default: yay)"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create necessary directories
mkdir -p "${REPORT_DIR}" "${CACHE_DIR}"

# Initialize report file
{
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    ARCH LINUX PACKAGE UPDATE REPORT                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo ""
} > "${REPORT_FILE}"

# Function to print section headers
print_section() {
    local title="$1"
    echo "" | tee -a "${REPORT_FILE}"
    echo "═══════════════════════════════════════════════════════════════════════════" | tee -a "${REPORT_FILE}"
    echo "  ${title}" | tee -a "${REPORT_FILE}"
    echo "═══════════════════════════════════════════════════════════════════════════" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
}

# Function to get package changelog
get_changelog() {
    local pkg="$1"
    local old_ver="$2"
    local new_ver="$3"
    
    if [[ "${SHOW_CHANGELOG}" == false ]]; then
        return
    fi
    
    echo "  Changelog:" | tee -a "${REPORT_FILE}"
    
    # Try to get pacman log entries
    if [[ -f /var/log/pacman.log ]]; then
        local log_entries
        log_entries=$(grep -i "upgraded.*${pkg}" /var/log/pacman.log 2>/dev/null | tail -n 3 || true)
        if [[ -n "${log_entries}" ]]; then
            echo "${log_entries}" | sed 's/^/    /' | tee -a "${REPORT_FILE}"
        fi
    fi
    
    # Try to get Arch news (if recent)
    # Note: This is a simplified approach. Real changelog parsing would require package-specific logic
    echo "    ${old_ver} → ${new_ver}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
}

# Function to check official repository updates
check_official_updates() {
    print_section "OFFICIAL REPOSITORY UPDATES"
    
    if ! command -v checkupdates &> /dev/null; then
        echo "  ⚠ checkupdates not found. Install pacman-contrib package." | tee -a "${REPORT_FILE}"
        return 1
    fi
    
    local updates
    updates=$(checkupdates 2>/dev/null || true)
    
    if [[ -z "${updates}" ]]; then
        echo -e "${GREEN}✓ No official updates available${NC}" | tee -a "${REPORT_FILE}"
        return 0
    fi
    
    local count
    count=$(echo "${updates}" | wc -l)
    echo -e "${YELLOW}📦 ${count} official package(s) available for update:${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    
    while IFS= read -r line; do
        if [[ -z "${line}" ]]; then
            continue
        fi
        
        local pkg
        local old_ver
        local arrow
        local new_ver
        pkg=$(echo "${line}" | awk '{print $1}')
        old_ver=$(echo "${line}" | awk '{print $2}')
        arrow=$(echo "${line}" | awk '{print $3}')
        new_ver=$(echo "${line}" | awk '{print $4}')
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "${REPORT_FILE}"
        echo -e "${BOLD}Package:${NC} ${pkg}" | tee -a "${REPORT_FILE}"
        echo "  Current Version:  ${old_ver}" | tee -a "${REPORT_FILE}"
        echo "  New Version:      ${new_ver}" | tee -a "${REPORT_FILE}"
        
        # Get repository information
        local repo
        repo=$(pacman -Si "${pkg}" 2>/dev/null | grep "Repository" | awk '{print $3}' || echo "unknown")
        echo "  Repository:       ${repo}" | tee -a "${REPORT_FILE}"
        
        # Get package description
        if [[ "${DETAILED}" == true ]]; then
            local description
            description=$(pacman -Si "${pkg}" 2>/dev/null | grep "Description" | cut -d: -f2- | sed 's/^[[:space:]]*//' || echo "")
            if [[ -n "${description}" ]]; then
                echo "  Description:      ${description}" | tee -a "${REPORT_FILE}"
            fi
            
            # Get package size
            local size
            size=$(pacman -Si "${pkg}" 2>/dev/null | grep "Download Size" | cut -d: -f2- | sed 's/^[[:space:]]*//' || echo "")
            if [[ -n "${size}" ]]; then
                echo "  Download Size:    ${size}" | tee -a "${REPORT_FILE}"
            fi
        fi
        
        # Get changelog information
        get_changelog "${pkg}" "${old_ver}" "${new_ver}"
        
    done <<< "${updates}"
    
    echo "" | tee -a "${REPORT_FILE}"
    return 0
}

# Function to check AUR updates
check_aur_updates() {
    print_section "AUR PACKAGE UPDATES"
    
    if ! command -v "${AUR_HELPER}" &> /dev/null; then
        echo "  ⚠ ${AUR_HELPER} not found. Install an AUR helper (yay or paru)." | tee -a "${REPORT_FILE}"
        return 1
    fi
    
    local updates
    updates=$("${AUR_HELPER}" -Qua 2>/dev/null || true)
    
    if [[ -z "${updates}" ]]; then
        echo -e "${GREEN}✓ No AUR updates available${NC}" | tee -a "${REPORT_FILE}"
        return 0
    fi
    
    local count
    count=$(echo "${updates}" | wc -l)
    echo -e "${CYAN}📦 ${count} AUR package(s) available for update:${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    
    while IFS= read -r line; do
        if [[ -z "${line}" ]]; then
            continue
        fi
        
        local pkg
        local old_ver
        local arrow
        local new_ver
        pkg=$(echo "${line}" | awk '{print $1}')
        old_ver=$(echo "${line}" | awk '{print $2}')
        arrow=$(echo "${line}" | awk '{print $3}')
        new_ver=$(echo "${line}" | awk '{print $4}')
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "${REPORT_FILE}"
        echo -e "${BOLD}Package:${NC} ${pkg}" | tee -a "${REPORT_FILE}"
        echo "  Current Version:  ${old_ver}" | tee -a "${REPORT_FILE}"
        echo "  New Version:      ${new_ver}" | tee -a "${REPORT_FILE}"
        echo "  Repository:       AUR" | tee -a "${REPORT_FILE}"
        
        # Get AUR package details
        if [[ "${DETAILED}" == true ]]; then
            local description
            description=$("${AUR_HELPER}" -Si "${pkg}" 2>/dev/null | grep "Description" | cut -d: -f2- | sed 's/^[[:space:]]*//' || echo "")
            if [[ -n "${description}" ]]; then
                echo "  Description:      ${description}" | tee -a "${REPORT_FILE}"
            fi
            
            # Get AUR URL
            local aur_url="https://aur.archlinux.org/packages/${pkg}"
            echo "  AUR URL:          ${aur_url}" | tee -a "${REPORT_FILE}"
        fi
        
        get_changelog "${pkg}" "${old_ver}" "${new_ver}"
        
    done <<< "${updates}"
    
    echo "" | tee -a "${REPORT_FILE}"
    return 0
}

# Function to check for important updates (like VS Code)
check_critical_packages() {
    print_section "CRITICAL PACKAGE STATUS"

    local critical_packages=("code" "visual-studio-code-bin" "linux" "linux-lts")
    local found_updates=false

    for pkg in "${critical_packages[@]}"; do
        if pacman -Q "${pkg}" &>/dev/null || "${AUR_HELPER}" -Q "${pkg}" &>/dev/null; then
            local current_ver
            current_ver=$(pacman -Q "${pkg}" 2>/dev/null | awk '{print $2}' || "${AUR_HELPER}" -Q "${pkg}" 2>/dev/null | awk '{print $2}')

            local available_ver
            local is_aur=false

            # Check official repos first
            available_ver=$(pacman -Si "${pkg}" 2>/dev/null | grep "Version" | awk '{print $3}')

            # If not in official repos, check AUR
            if [[ -z "${available_ver}" ]]; then
                available_ver=$("${AUR_HELPER}" -Si "${pkg}" 2>/dev/null | grep "Version" | awk '{print $3}')
                is_aur=true
            fi

            if [[ "${current_ver}" != "${available_ver}" ]] && [[ -n "${available_ver}" ]]; then
                found_updates=true
                echo -e "${RED}⚠ CRITICAL:${NC} ${pkg}" | tee -a "${REPORT_FILE}"
                echo "  Installed: ${current_ver}" | tee -a "${REPORT_FILE}"
                echo "  Available: ${available_ver}" | tee -a "${REPORT_FILE}"
                echo "" | tee -a "${REPORT_FILE}"

                # Track critical updates by source
                if [[ "${is_aur}" == true ]]; then
                    CRITICAL_UPDATES_AUR+=("${pkg}")
                else
                    CRITICAL_UPDATES_OFFICIAL+=("${pkg}")
                fi
            fi
        fi
    done

    if [[ "${found_updates}" == false ]]; then
        echo -e "${GREEN}✓ All critical packages are up to date${NC}" | tee -a "${REPORT_FILE}"
    fi

    echo "" | tee -a "${REPORT_FILE}"
}

# Function to generate summary
generate_summary() {
    print_section "SUMMARY"

    local official_count
    local aur_count
    official_count=$(checkupdates 2>/dev/null | wc -l 2>/dev/null || true)
    [[ -z "$official_count" || "$official_count" == *$'\n'* ]] && official_count=0
    aur_count=$("${AUR_HELPER}" -Qua 2>/dev/null | wc -l 2>/dev/null || true)
    [[ -z "$aur_count" || "$aur_count" == *$'\n'* ]] && aur_count=0
    # Ensure they are valid numbers
    official_count=${official_count//[^0-9]/}
    aur_count=${aur_count//[^0-9]/}
    [[ -z "$official_count" ]] && official_count=0
    [[ -z "$aur_count" ]] && aur_count=0
    local total_count=$((official_count + aur_count))

    local critical_count=$((${#CRITICAL_UPDATES_OFFICIAL[@]} + ${#CRITICAL_UPDATES_AUR[@]}))

    {
        echo "Total Updates Available: ${total_count}"
        echo "  - Official Repositories: ${official_count}"
        echo "  - AUR: ${aur_count}"

        if [[ ${critical_count} -gt 0 ]]; then
            echo "  - Critical Updates: ${critical_count}"
        fi

        echo ""

        # Suggest appropriate update command
        if [[ ${critical_count} -gt 0 ]]; then
            echo "Recommended Action:"

            # Build package list for critical updates
            local critical_pkgs=()
            for pkg in "${CRITICAL_UPDATES_OFFICIAL[@]}"; do
                critical_pkgs+=("${pkg}")
            done
            for pkg in "${CRITICAL_UPDATES_AUR[@]}"; do
                critical_pkgs+=("${pkg}")
            done

            if [[ ${#critical_pkgs[@]} -gt 0 ]]; then
                echo "  Update critical packages first:"

                # Determine which command to use based on package sources
                if [[ ${#CRITICAL_UPDATES_AUR[@]} -gt 0 ]]; then
                    # If any critical packages are from AUR, use AUR helper
                    echo "    ${AUR_HELPER} -S ${critical_pkgs[*]}"
                else
                    # All critical packages are from official repos
                    echo "    sudo pacman -S ${critical_pkgs[*]}"
                fi
                echo ""
            fi

            if [[ ${total_count} -gt ${critical_count} ]]; then
                echo "  Then update remaining packages:"
                echo "    ${AUR_HELPER} -Syu"
            fi
        elif [[ ${total_count} -gt 0 ]]; then
            echo "Recommended Action:"
            echo "  Update all packages:"
            if [[ ${aur_count} -gt 0 ]]; then
                echo "    ${AUR_HELPER} -Syu"
            else
                echo "    sudo pacman -Syu"
            fi
        else
            echo "✓ System is up to date"
        fi

        echo ""
        echo "Alternative Update Commands:"
        echo "  Official packages only: sudo pacman -Syu"
        echo "  All packages:           ${AUR_HELPER} -Syu"
        echo ""
        echo "Report saved to: ${REPORT_FILE}"
    } | tee -a "${REPORT_FILE}"
}

# Function to send desktop notification
send_notification() {
    if [[ "${NOTIFY}" == false ]] || ! command -v notify-send &> /dev/null; then
        return
    fi
    
    local official_count
    local aur_count
    official_count=$(checkupdates 2>/dev/null | wc -l 2>/dev/null || true)
    aur_count=$("${AUR_HELPER}" -Qua 2>/dev/null | wc -l 2>/dev/null || true)
    # Ensure they are valid numbers
    official_count=${official_count//[^0-9]/}
    aur_count=${aur_count//[^0-9]/}
    [[ -z "$official_count" ]] && official_count=0
    [[ -z "$aur_count" ]] && aur_count=0
    local total_count=$((official_count + aur_count))
    
    if [[ ${total_count} -gt 0 ]]; then
        notify-send -u normal -t 10000 \
            "📦 Package Updates Available" \
            "${total_count} update(s) available\nOfficial: ${official_count} | AUR: ${aur_count}\n\nRun check-updates.sh for details"
    else
        notify-send -u low -t 5000 \
            "✓ System Up to Date" \
            "No package updates available"
    fi
}

# Main execution
main() {
    echo -e "${BOLD}${BLUE}Checking for package updates...${NC}"
    echo ""
    
    # Sync package databases (quietly)
    # Note: Syncing requires sudo. For automated runs via systemd,
    # ensure pacman -Sy is in sudoers or run manual sync before checking.
    if [[ -t 0 ]]; then
        # Only sync if running interactively (has a terminal)
        echo "Syncing package databases..."
        sudo pacman -Sy > /dev/null 2>&1
    else
        echo "Running in non-interactive mode, skipping database sync..."
        echo "Run 'sudo pacman -Sy' manually if needed."
    fi
    
    # Run checks
    check_official_updates
    check_aur_updates
    check_critical_packages
    generate_summary
    
    # Send notification
    send_notification
    
    # Update last check time
    date +%s > "${LAST_CHECK_FILE}"
    
    echo ""
    echo -e "${GREEN}✓ Update check complete!${NC}"
    echo -e "Full report: ${CYAN}${REPORT_FILE}${NC}"
}

# Run main function
main
