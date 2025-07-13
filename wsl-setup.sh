#!/bin/bash

# Update & install core packages
sudo apt update && sudo apt upgrade -y
sudo apt install git curl unzip build-essential -y

# --- Install Java 21 ---
sudo apt install openjdk-21-jdk -y
echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64" >> ~/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc

# --- Install Maven ---
sudo apt install maven -y

# --- Install Docker ---
sudo apt install docker.io -y
sudo systemctl enable docker
sudo usermod -aG docker $USER

# --- Install NVM, Node, npm ---
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install node
nvm use node

# --- Clone Repo ---
git clone https://gitlab.com/YOUR_USERNAME/YOUR_REPO_NAME.git ~/dev-project

echo "✅ WSL2 Dev Environment Ready. Restart terminal to apply environment variables."
