#!/bin/bash

# Define color codes
INFO='\033[0;36m'  # Cyan
WARNING='\033[0;33m'
ERROR='\033[0;31m'
SUCCESS='\033[0;32m'
NC='\033[0m' # No Color

# Prompt for username and password
while true; do
    read -p "Enter the username for remote desktop: " USER
    if [[ "$USER" == "root" ]]; then
        echo -e "${ERROR}Error: 'root' cannot be used as the username. Please choose a different username.${NC}"
    elif [[ "$USER" =~ [^a-zA-Z0-9] ]]; then
        echo -e "${ERROR}Error: Username contains forbidden characters. Only alphanumeric characters are allowed.${NC}"
    else
        break
    fi
done

while true; do
    read -sp "Enter the password for $USER: " PASSWORD
    echo
    if [[ "$PASSWORD" =~ [^a-zA-Z0-9] ]]; then
        echo -e "${ERROR}Error: Password contains forbidden characters. Only alphanumeric characters are allowed.${NC}"
    else
        break
    fi
done

# Update and install required packages
echo -e "${INFO}Updating package list...${NC}"
sudo apt update

echo -e "${INFO}Installing curl and gdebi for handling .deb files...${NC}"
sudo apt install -y curl gdebi-core

# Download AdsPower .deb package
echo -e "${INFO}Downloading AdsPower package...${NC}"
curl -O https://version.adspower.net/software/linux-x64-global/AdsPower-Global-7.3.26-x64.deb

# Install AdsPower using gdebi
echo -e "${INFO}Installing AdsPower using gdebi...${NC}"
sudo gdebi -n AdsPower-Global-7.3.26-x64.deb

# Install GNOME and XRDP
echo -e "${INFO}Installing GNOME Desktop...${NC}"
sudo apt install -y ubuntu-desktop gnome-shell

echo -e "${INFO}Installing XRDP for remote desktop...${NC}"
sudo apt install -y xrdp

echo -e "${INFO}Adding the user $USER with the specified password...${NC}"
sudo useradd -m -s /bin/bash $USER
echo "$USER:$PASSWORD" | sudo chpasswd

echo -e "${INFO}Adding $USER to the sudo group...${NC}"
sudo usermod -aG sudo $USER

# Configure XRDP to use GNOME
echo -e "${INFO}Configuring XRDP to use GNOME desktop...${NC}"
sudo tee /etc/xrdp/startwm.sh > /dev/null <<EOL
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
exec /usr/bin/gnome-session
EOL

sudo chmod +x /etc/xrdp/startwm.sh

# Configure XRDP for 800x600 resolution
echo -e "${INFO}Limiting XRDP resolution to 800x600 for lower resource usage...${NC}"
sudo sed -i '/\[xrdp1\]/a max_bpp=16\nxres=800\nyres=600' /etc/xrdp/xrdp.ini

# Restart and enable XRDP service
echo -e "${INFO}Restarting XRDP service...${NC}"
sudo systemctl restart xrdp

echo -e "${INFO}Enabling XRDP service at startup...${NC}"
sudo systemctl enable xrdp

# Ensure the Desktop directory exists
DESKTOP_DIR="/home/$USER/Desktop"
if [ ! -d "$DESKTOP_DIR" ]; then
    echo -e "${INFO}Desktop directory not found. Creating Desktop directory for $USER...${NC}"
    sudo mkdir -p "$DESKTOP_DIR"
    sudo chown $USER:$USER "$DESKTOP_DIR"
fi

# Create a desktop shortcut for AdsPower
DESKTOP_FILE="$DESKTOP_DIR/AdsPower.desktop"
echo -e "${INFO}Creating desktop shortcut for AdsPower...${NC}"

sudo tee $DESKTOP_FILE > /dev/null <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=AdsPower
Comment=Launch AdsPower
Exec="/opt/AdsPower Global/adspower_global" %U
Icon=/opt/AdsPower/resources/app/static/img/icon.png
Terminal=false
StartupNotify=true
Categories=Utility;Application;
EOL

# Set permissions for the desktop file
sudo chmod +x $DESKTOP_FILE
sudo chown $USER:$USER $DESKTOP_FILE

# Get the server IP address
IP_ADDR=$(hostname -I | awk '{print $1}')

# Final message
echo -e "${SUCCESS}Installation complete. GNOME Desktop, XRDP, AdsPower, and a desktop shortcut have been installed.${NC}"
echo -e "${INFO}You can now connect via Remote Desktop with the following details:${NC}"
echo -e "${INFO}IP ADDRESS: ${SUCCESS}$IP_ADDR${NC}"
echo -e "${INFO}USER: ${SUCCESS}$USER${NC}"
echo -e "${INFO}PASSWORD: ${SUCCESS}$PASSWORD${NC}"

# Restart the system
echo -e "${INFO}Rebooting system to apply all changes...${NC}"
sudo reboot
