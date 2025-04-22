# Automated Desktop and AdsPower Installer for Linux VPS

This script automates the setup of a desktop environment and AdsPower on your Linux VPS, making it easy to manage multiple bots or nodes. All you need to do is provide a non-root username and password for your remote desktop connection, and the script will handle the rest.

## How to Use the Installer Script

1. **Log into your VPS via SSH** using a terminal application like Putty or Termius.
2. Run the following commands to start the installation process:

    ```bash
    sudo apt update
    sudo apt install curl
    curl -O https://raw.githubusercontent.com/juliwicks/desktop-adspower-installer-fox-linux/refs/heads/main/nodebot_installer.sh && chmod +x nodebot_installer.sh && ./nodebot_installer.sh
    ```

3. When prompted, **enter the username and password** you’d like to use for your remote desktop connection. Avoid using the root username for security reasons.
4. The script will install the desktop environment and AdsPower. Simply wait until everything is fully installed.

## Accessing Your VPS Desktop

1. After installation, open **Remote Desktop Connection** on your PC.
2. Enter your **VPS address** and connect.
3. Input the **username and password** you provided during the setup.
4. Once connected, you can access **AdsPower Global** on your Linux VPS.
