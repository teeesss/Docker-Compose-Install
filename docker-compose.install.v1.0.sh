#!/bin/bash
# Version 1.0
# Prerequisites: curl jq realpath

# Check if the target installation directory exists
if [ -d "/volume1/@appstore/ContainerManager/usr/bin/" ]; then
    INSTALL_DIR="/volume1/@appstore/ContainerManager/usr/bin"
else
    # If the directory doesn't exist, use the custom install directory
    INSTALL_DIR="/usr/local/lib/docker/cli-plugins/"

    # Check if the custom directory exists, create it if not
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "Creating custom install directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi
fi

DOCKER_COMPOSE_PATH="$INSTALL_DIR/docker-compose"

# Function to display the current installed Docker-Compose version and path
function show_current_version() {
    if [ -x "$DOCKER_COMPOSE_PATH" ]; then
        current_version=$("$DOCKER_COMPOSE_PATH" version --short)
        echo "Current Docker-Compose version: $current_version"
        echo "Installed at: $DOCKER_COMPOSE_PATH"
    else
        echo "Docker-Compose is not currently installed."
    fi
}

# Function to display the latest 5 releases of Docker-Compose
function show_latest_releases() {
    releases=($(curl -s https://api.github.com/repos/docker/compose/releases | jq -r '.[0:5] | .[] | "\( .tag_name) \( .published_at)"'))

    # Display releases with index numbers
    for ((i=0; i<${#releases[@]}; i+=2)); do
        echo "$((i/2 + 1)). ${releases[i]} ${releases[i+1]//T/ }Z"
    done
}

# Function to install Docker-Compose based on the selected version
function install_docker_compose() {
    local version="$1"
    local download_url="https://github.com/docker/compose/releases/download/$version/docker-compose-$(uname -s)-$(uname -m)"

    echo "Version changing from $current_version to version $version"

    echo "Downloading Docker-Compose $version..."
    curl -L "$download_url" -o "$DOCKER_COMPOSE_PATH"

    echo "Installation completed successfully!"

    # Make the downloaded file executable
    chmod +x "$DOCKER_COMPOSE_PATH"

    # Display the current version and installation path after installation
    show_current_version
}

# Display the current version
show_current_version

# Display the retrieval line before getting user input
echo "Retrieving last 5 Docker Compose Releases..."

# Display the releases and get the user input
show_latest_releases
read -p "Enter the number of the Docker-Compose version to install: " choice

# Validate user input
if [[ $choice =~ ^[1-5]$ ]]; then
    selected_version=$(echo "${releases[($choice-1)*2]}" | cut -d' ' -f1)

    # Install the selected version
    install_docker_compose "$selected_version"
else
    echo "Invalid choice. Exiting..."
fi
