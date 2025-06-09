# Docker-Compose-Install
Docker Compose Installation Script for Synology NAS


Example of the output

```
./docker-compose-install.sh
--- Docker Compose Updater v3.0 ---
--- 1. Checking Prerequisites ---
All dependencies are satisfied.

================================= IMPORTANT ==================================
NOTE: You are running this on a Synology NAS.
Updating the 'Container Manager' package from the Package Center will
likely OVERWRITE the docker-compose version you install with this script.
If that happens, simply run this script again.
============================================================================

--- 2. Locating Docker Compose ---
Current Version: 2.36.2
Installed at:    /volume1/@appstore/ContainerManager/usr/bin/docker-compose

--- 3. Fetching Available Releases from GitHub ---
  1. v2.37.0         2025-06-05 10:11
  2. v2.36.2         2025-05-23 09:21 (current)
  3. v2.36.1         2025-05-19 07:26
  4. v2.36.0         2025-05-07 06:54
  5. v2.35.1         2025-04-17 09:29

Enter the number of the version to install (or 'q' to quit): 1
--- 4. Starting Update Process ---
Target version: v2.37.0
Downloading from: https://github.com/docker/compose/releases/download/v2.37.0/docker-compose-Linux-x86_64
Download complete. ✓
Backing up existing version...
./dockerc.sh: line 177: 29762 Terminated              ( while true; do
    for s in / - \\ \|;
    do
        printf "\rDownloading... %s" "$s"; sleep 0.1;
    done;
done )
Backup created at: /volume1/@appstore/ContainerManager/usr/bin/docker-compose.bak-20250608-232833
Installing new version...
--- 5. Verifying Installation ---
Update successful!
New Docker Compose Version: 2.37.0

All done!
