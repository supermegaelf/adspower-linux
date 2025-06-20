### Automated Desktop and AdsPower Installer for Linux VPS

This script automates the setup of a desktop environment and AdsPower on your Linux VPS, making it easy to manage multiple bots or nodes.

#### How to Use the Installer Script

1. **Log into your VPS via SSH** using a terminal application like Putty or Termius.
2. Run the following command to start the installation process:

```
bash <(curl -s https://raw.githubusercontent.com/supermegaelf/adspower-linux/main/adspower-linux.sh)
```

3. When prompted, **enter the username and password** you’d like to use for your remote desktop connection.
4. The script will install the desktop environment and AdsPower. Simply wait until everything is fully installed.

## Accessing Your VPS Desktop

1. After installation, open `RealVNC` Viewer on your PC.
2. Enter your `VPS address` and connect with `5901` port.
