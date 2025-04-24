# 🚀 Ubuntu 25.04 Dev Environment Setup Script

This script sets up a full web development environment on a fresh installation of **Ubuntu 25.04**. It's perfect for developers who want to quickly get started with tools like Node.js, Docker, .NET SDK, Git, and Visual Studio Code.

## 📦 What It Installs

- 🔧 Essential tools: `curl`, `wget`, `git`, `build-essential`
- 🟢 Node.js (via NVM, LTS version)
- 🐙 Git
- 🐳 Docker and Docker Compose
- 🖥️ Visual Studio Code (latest stable)
- 💠 .NET SDK 8.0

## 🛠️ Usage

Clone the repo and run the script:

```bash
git clone https://github.com/Nattie-Nkosi/ubuntu-dev-setup.git
cd YOUR_REPO_NAME
chmod +x ubuntu-dev-setup.sh
./ubuntu-dev-setup.sh
```

⚠️ After the script completes, reboot your system to activate Docker permissions.

## ✅ Tested On

- Ubuntu 25.04 (Lunar Lobster)

## 📌 Notes

Make sure to verify your installations:

```bash
node -v
npm -v
git --version
dotnet --version
docker --version
code --version
```

You can customize this script by adding Python, PostgreSQL, MySQL, or any other tools you use.

## 🙌 Contributing

Feel free to fork and improve the script for your use case. Pull requests welcome!
