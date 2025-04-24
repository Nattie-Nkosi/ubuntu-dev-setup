# Update and upgrade
sudo apt update && sudo apt upgrade -y

# Essential tools
sudo apt install -y curl wget git build-essential apt-transport-https software-properties-common ca-certificates gnupg lsb-release

# ------------------------------
# Node.js (via NVM)
# ------------------------------
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# Load NVM immediately for this session
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# ------------------------------
# Git
# ------------------------------
sudo apt install -y git

# ------------------------------
# Docker and Docker Compose
# ------------------------------
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo usermod -aG docker $USER

# ------------------------------
# Visual Studio Code
# ------------------------------
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code
rm microsoft.gpg

# ------------------------------
# .NET SDK 8.0
# ------------------------------
wget https://packages.microsoft.com/config/ubuntu/25.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-8.0
rm packages-microsoft-prod.deb

# ------------------------------
# Done
# ------------------------------
echo ""
echo "✅ Development environment setup complete!"
echo "⚠️ Please reboot your system to apply Docker group permissions."
