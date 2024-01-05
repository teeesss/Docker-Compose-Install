#!/bin/bash

# Prerequisites: curl jq realpath

# Find the real location of docker-compose without following the symlink
DOCKER_COMPOSE_PATH=$(readlink -f $(command -v docker-compose))

# Set executable permissions for docker-compose
sudo chmod 755 "$DOCKER_COMPOSE_PATH"

# Function to display the current installed Docker-Compose version
function show_current_version() {
    if [ -f "$DOCKER_COMPOSE_PATH" ]; then
        current_version=$("$DOCKER_COMPOSE_PATH" version --short)
        echo "Current Docker-Compose version: $current_version"
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
    curl -L "$download_url" -o docker-compose

    echo "Renaming docker-compose..."
    mv "$DOCKER_COMPOSE_PATH" "${DOCKER_COMPOSE_PATH}-backup"

    echo -n "Moving the new docker-compose to... "
    mv docker-compose "$(dirname "$DOCKER_COMPOSE_PATH")" 2>&1 | tee -a installation_log.txt
    echo "$(dirname "$DOCKER_COMPOSE_PATH")/docker-compose" # Display the full path

    # Reset permissions after moving
    sudo chmod 755 "$(dirname "$DOCKER_COMPOSE_PATH")/docker-compose"

    echo "Installation completed successfully!"

    # Display the current version after installation
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
