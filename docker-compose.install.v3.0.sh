#!/bin/bash
#
# Docker Compose Updater for Synology NAS
# Version 3.0
#
# A robust script to safely update Docker Compose, with backups, logging,
# and UI enhancements. Aware of the Synology DSM environment.
#

# --- Configuration ---
readonly SCRIPT_VERSION="3.0"
readonly LOG_FILE="/var/log/docker-compose-updater.log"
readonly SCRIPT_NAME=$(basename "$0")

# --- Shell Settings for Robustness ---
# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Pipelines return the exit status of the last command to fail, not the last command.
set -o pipefail

# --- Color Definitions ---
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'

# --- Helper Functions ---
function print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${COLOR_RESET}"
}

function log_message() {
    # Logs to the specified log file with a timestamp.
    # Needs to be run with sudo to write to /var/log.
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

function header() {
    print_color "$COLOR_BOLD" "--- $1 ---"
}

function cleanup() {
  # Remove temporary file on exit
  if [[ -n "${TMP_FILE-}" && -f "$TMP_FILE" ]]; then
    rm -f "$TMP_FILE"
  fi
}

# --- Pre-flight Checks ---
# Ensure the script is run as root
if [[ "$(id -u)" -ne 0 ]]; then
  print_color "$COLOR_RED" "Error: This script must be run with root privileges."
  print_color "$COLOR_YELLOW" "Please use 'sudo ./$SCRIPT_NAME'"
  exit 1
fi

# Register the cleanup function to run on script exit
trap cleanup EXIT

header "Docker Compose Updater v${SCRIPT_VERSION}"

# Check for required dependencies
header "1. Checking Prerequisites"
for cmd in curl jq; do
  if ! command -v "$cmd" &> /dev/null; then
    print_color "$COLOR_RED" "Error: Required command '$cmd' is not installed. Please install it."
    exit 1
  fi
done
print_color "$COLOR_GREEN" "All dependencies are satisfied."
echo ""

# --- Synology Specific Warning ---
print_color "$COLOR_YELLOW" "================================= IMPORTANT =================================="
print_color "$COLOR_YELLOW" "NOTE: You are running this on a Synology NAS."
print_color "$COLOR_YELLOW" "Updating the 'Container Manager' package from the Package Center will"
print_color "$COLOR_RED"   "likely OVERWRITE the docker-compose version you install with this script."
print_color "$COLOR_YELLOW" "If that happens, simply run this script again."
print_color "$COLOR_YELLOW" "============================================================================"
echo ""

# --- Main Logic ---
# Find the docker-compose binary
header "2. Locating Docker Compose"
INSTALL_DIR=""
if [ -f "/volume1/@appstore/ContainerManager/usr/bin/docker-compose" ]; then
    INSTALL_DIR="/volume1/@appstore/ContainerManager/usr/bin"
elif [ -f "/usr/local/lib/docker/cli-plugins/docker-compose" ]; then
    INSTALL_DIR="/usr/local/lib/docker/cli-plugins"
fi

if [[ -z "$INSTALL_DIR" ]]; then
    print_color "$COLOR_RED" "Error: Could not find an existing docker-compose installation."
    exit 1
fi

DOCKER_COMPOSE_PATH="$INSTALL_DIR/docker-compose"
CURRENT_VERSION=$($DOCKER_COMPOSE_PATH version --short || echo "not installed")

print_color "$COLOR_CYAN" "Current Version: $CURRENT_VERSION"
print_color "$COLOR_CYAN" "Installed at:    $DOCKER_COMPOSE_PATH"
echo ""

# Get and display available releases
header "3. Fetching Available Releases from GitHub"
RELEASES_JSON=$(curl --silent --fail https://api.github.com/repos/docker/compose/releases)
releases=($(echo "$RELEASES_JSON" | jq -r '.[0:5] | .[] | "\(.tag_name) \(.published_at)"'))

for ((i=0; i<${#releases[@]}; i+=2)); do
    version_tag="${releases[i]}"
    # Add a marker if the version is currently installed
    marker=""
    if [[ "$version_tag" == "v$CURRENT_VERSION" ]]; then
        marker=" (current)"
    fi
    printf "  %s. %-15s %s%s\n" "$((i/2 + 1))" "${version_tag}" "$(date -d "${releases[i+1]}" "+%Y-%m-%d %H:%M")" "${marker}"
done
echo ""

# Get user choice
read -p "Enter the number of the version to install (or 'q' to quit): " choice

if [[ "$choice" =~ ^[qQ]$ ]] || [[ -z "$choice" ]]; then
    print_color "$COLOR_YELLOW" "No selection made. Exiting."
    exit 0
fi

# Validate input and select version
if ! [[ "$choice" =~ ^[1-5]$ ]]; then
    print_color "$COLOR_RED" "Invalid choice. Please enter a number between 1 and 5."
    exit 1
fi

selected_version=$(echo "${releases[($choice-1)*2]}" | cut -d' ' -f1)

if [[ "v$CURRENT_VERSION" == "$selected_version" ]]; then
    print_color "$COLOR_GREEN" "You already have version $selected_version installed. Nothing to do."
    exit 0
fi

# --- Update Process ---
header "4. Starting Update Process"
log_message "Update initiated by user. Attempting to switch from $CURRENT_VERSION to $selected_version."
print_color "$COLOR_CYAN" "Target version: $selected_version"

# Download
download_url="https://github.com/docker/compose/releases/download/$selected_version/docker-compose-$(uname -s)-$(uname -m)"
TMP_FILE=$(mktemp)

print_color "$COLOR_CYAN" "Downloading from: $download_url"
# Spinner animation
(
    while true; do
        for s in / - \\ \|; do printf "\rDownloading... %s" "$s"; sleep 0.1; done
    done
) &
SPINNER_PID=$!
# Kill the spinner on exit
trap 'kill $SPINNER_PID; cleanup' EXIT

# Perform the download silently, fail on error
curl --silent -L --fail --show-error "$download_url" -o "$TMP_FILE"
# Stop the spinner
kill $SPINNER_PID
trap cleanup EXIT # Reset trap to just cleanup
printf "\r%s\n" "Download complete. ✓"

# Backup, Replace, and Set Permissions
print_color "$COLOR_CYAN" "Backing up existing version..."
BACKUP_PATH="${DOCKER_COMPOSE_PATH}.bak-$(date +"%Y%m%d-%H%M%S")"
cp "$DOCKER_COMPOSE_PATH" "$BACKUP_PATH"
print_color "$COLOR_GREEN" "Backup created at: $BACKUP_PATH"

print_color "$COLOR_CYAN" "Installing new version..."
mv "$TMP_FILE" "$DOCKER_COMPOSE_PATH"
chmod +x "$DOCKER_COMPOSE_PATH"

# Final verification
header "5. Verifying Installation"
NEW_VERSION=$($DOCKER_COMPOSE_PATH version --short)
print_color "$COLOR_GREEN" "Update successful!"
print_color "$COLOR_CYAN" "New Docker Compose Version: $NEW_VERSION"
log_message "Update successful. New version $NEW_VERSION installed."
echo ""
print_color "$COLOR_BOLD" "All done!"
