#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# NVM version to install (check https://github.com/nvm-sh/nvm/releases for latest)
NVM_VERSION="v0.39.7"
# Node.js version (use 'lts' for the latest Long Term Support version)
NODE_VERSION="lts"
# .NET SDK Version
DOTNET_SDK_VERSION="8.0"

# --- Helper Functions ---
print_header() {
    echo ""
    echo "--------------------------------------------------"
    echo "$1"
    echo "--------------------------------------------------"
}

# Check if running as root, exit if true as we use sudo intentionally
if [ "$(id -u)" -eq 0 ]; then
   echo "This script should not be run as root. It uses sudo internally." >&2
   exit 1
fi

# Refresh sudo timestamp at the beginning
sudo -v
# Keep sudo session alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- Main Setup ---

install_base_system() {
    print_header "Updating Package Lists and Upgrading System"
    sudo apt update
    sudo apt upgrade -y
}

install_essential_tools() {
    print_header "Installing Essential Tools & Build Dependencies"
    # build-essential: Common build tools (make, gcc, etc.)
    # curl, wget: Data transfer tools
    # git: Version control
    # apt-transport-https, ca-certificates: For adding HTTPS apt repositories
    # software-properties-common: For `add-apt-repository`
    # gnupg: For handling GPG keys
    # lsb-release: For identifying Linux distribution
    # jq: Command-line JSON processor
    # zsh: Z Shell (popular alternative)
    sudo apt install -y \
        build-essential \
        curl \
        wget \
        git \
        apt-transport-https \
        ca-certificates \
        software-properties-common \
        gnupg \
        lsb-release \
        jq \
        zsh
}

install_nvm_node() {
    print_header "Installing Node Version Manager (NVM) and Node.js ($NODE_VERSION)"
    # Check if NVM is already installed
    if [ -d "$HOME/.nvm" ]; then
        echo "NVM already installed. Skipping NVM installation."
    else
        # Install NVM
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    fi

    # Export NVM environment variables for the current script session
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        . "$NVM_DIR/nvm.sh"
        echo "NVM sourced for current session."
    else
        echo "Error: NVM installation failed or nvm.sh not found." >&2
        exit 1
    fi

    # Ensure NVM is loaded in future shell sessions (.bashrc)
    local NVM_LOAD_CMD='export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' # This loads nvm
    if ! grep -q "NVM_DIR" "$HOME/.bashrc"; then
        echo "Adding NVM setup to ~/.bashrc"
        echo "" >> "$HOME/.bashrc"
        echo "# NVM Loader" >> "$HOME/.bashrc"
        echo "$NVM_LOAD_CMD" >> "$HOME/.bashrc"
    else
        echo "NVM setup already found in ~/.bashrc"
    fi

    # Ensure NVM is loaded in future shell sessions (.zshrc)
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "NVM_DIR" "$HOME/.zshrc"; then
            echo "Adding NVM setup to ~/.zshrc"
            echo "" >> "$HOME/.zshrc"
            echo "# NVM Loader" >> "$HOME/.zshrc"
            echo "$NVM_LOAD_CMD" >> "$HOME/.zshrc"
        else
            echo "NVM setup already found in ~/.zshrc"
        fi
    fi

    # Install the desired Node.js version
    echo "Installing Node.js ($NODE_VERSION)..."
    nvm install "$NODE_VERSION"
    # Set the installed version as the default
    nvm alias default "$NODE_VERSION"
    # Use the installed version immediately
    nvm use default

    echo "Node.js version:"
    node -v
    echo "NPM version:"
    npm -v
}

configure_git() {
    print_header "Configuring Git (Placeholder)"
    echo "Reminder: Configure your Git user name and email:"
    echo "  git config --global user.name \"Your Name\""
    echo "  git config --global user.email \"your.email@example.com\""
    # You can optionally uncomment and run these lines if you want the script to prompt
    # read -p "Enter your Git user name: " git_user_name
    # read -p "Enter your Git user email: " git_user_email
    # git config --global user.name "$git_user_name"
    # git config --global user.email "$git_user_email"
    # echo "Git user name and email configured globally."
}

install_docker() {
    print_header "Installing Docker and Docker Compose Plugin"

    # Remove old versions if they exist
    echo "Removing older Docker versions if present..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt remove -y $pkg || true # Use '|| true' to ignore errors if package isn't installed
    done
    sudo apt autoremove -y

    # Add Docker's official GPG key
    echo "Adding Docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo "Setting up Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine, CLI, Containerd, and Compose Plugin
    echo "Installing Docker components..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to the docker group
    echo "Adding current user ($USER) to the 'docker' group..."
    sudo usermod -aG docker "$USER"

    # Enable Docker service to start on boot
    echo "Enabling Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker # Start it now as well

    echo "Docker installation complete. Version info:"
    docker --version
    docker compose version

    echo "⚠️ IMPORTANT: You need to log out and log back in, or reboot, for the Docker group changes to take effect."
}

install_vscode() {
    print_header "Installing Visual Studio Code"

    # Check if already installed
    if command -v code &> /dev/null; then
        echo "Visual Studio Code is already installed."
        return
    fi

    echo "Adding Microsoft GPG key and repository..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg

    echo "Installing VS Code..."
    sudo apt update
    sudo apt install -y code

    echo "VS Code installation complete."
}

install_dotnet_sdk() {
    print_header "Installing .NET SDK ($DOTNET_SDK_VERSION)"

    # Check if .NET SDK is already installed (basic check)
    if command -v dotnet &> /dev/null && dotnet --list-sdks | grep -q "$DOTNET_SDK_VERSION"; then
        echo ".NET SDK $DOTNET_SDK_VERSION seems to be already installed."
        return
    fi

    # Add Microsoft package signing key and repository feed
    # Based on standard Microsoft instructions - attempts to detect Ubuntu version
    echo "Adding Microsoft package repository for .NET..."
    local UBUNTU_VERSION_CODE_NAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
    local DEB_FILE="packages-microsoft-prod.deb"

    wget "https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION_CODE_NAME}/packages-microsoft-prod.deb" -O "$DEB_FILE"
    sudo dpkg -i "$DEB_FILE"
    rm "$DEB_FILE"

    echo "Installing .NET SDK $DOTNET_SDK_VERSION..."
    sudo apt update
    sudo apt install -y apt-transport-https # Ensure this is present
    sudo apt install -y "dotnet-sdk-${DOTNET_SDK_VERSION}"

    echo ".NET SDK installation complete. Installed SDKs:"
    dotnet --list-sdks
}

install_db_clients() {
    print_header "Installing Database CLI Clients (PostgreSQL, MySQL)"
    sudo apt install -y postgresql-client mysql-client
    echo "Database clients installed."
    echo "Test with: psql --version, mysql --version"
}

cleanup() {
    print_header "Cleaning up apt cache"
    sudo apt autoremove -y
    sudo apt clean
}

# --- Script Execution ---
install_base_system
install_essential_tools
install_nvm_node
configure_git # Reminder step
install_docker
install_vscode
install_dotnet_sdk
install_db_clients
cleanup

# --- Final Messages ---
print_header "✅ Development Environment Setup Complete!"
echo "Installed Components:"
echo "  - Essential build tools, curl, wget, git, jq, zsh"
echo "  - NVM (Node Version Manager)"
echo "  - Node.js $(node -v) (set as default)"
echo "  - NPM $(npm -v)"
echo "  - Docker Engine & Docker Compose Plugin"
echo "  - Visual Studio Code"
echo "  - .NET SDK $(dotnet --version || echo 'Not detected')"
echo "  - PostgreSQL & MySQL Client Tools"
echo ""
echo "Recommendations & Next Steps:"
echo "  1. Configure Git with your name and email (see reminder above)."
echo "  2. ‼️ IMPORTANT: Log out and log back in OR reboot your system now."
echo "     This is required to:"
echo "       - Apply Docker group membership (to run docker without sudo)."
echo "       - Ensure NVM is available in all new terminal sessions."
echo "  3. Consider exploring Zsh with Oh My Zsh for an enhanced terminal:"
echo "     sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
echo "  4. Open VS Code ('code' command) and install any desired extensions."
echo ""
echo "Enjoy your enhanced development environment!"

exit 0