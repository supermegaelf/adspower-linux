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

# Prompt for VNC password
while true; do
    read -sp "Enter the VNC password (6-8 characters): " VNC_PASSWORD
    echo
    if [[ ${#VNC_PASSWORD} -lt 6 || ${#VNC_PASSWORD} -gt 8 ]]; then
        echo -e "${ERROR}Error: VNC password must be 6-8 characters long.${NC}"
    elif [[ "$VNC_PASSWORD" =~ [^a-zA-Z0-9] ]]; then
        echo -e "${ERROR}Error: VNC password contains forbidden characters. Only alphanumeric characters are allowed.${NC}"
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

# Install XFCE Desktop Environment (lighter than GNOME)
echo -e "${INFO}Installing XFCE Desktop Environment...${NC}"
sudo apt install -y xfce4 xfce4-goodies

# Install VNC Server and required components
echo -e "${INFO}Installing TightVNC Server and components...${NC}"
sudo apt install -y tightvncserver
sudo apt install -y xfonts-base xfonts-75dpi xfonts-100dpi
sudo apt install -y dbus-x11 x11-xserver-utils

# Install clipboard synchronization tools
echo -e "${INFO}Installing clipboard synchronization tools...${NC}"
sudo apt install -y autocutsel xsel xclip

# Install and configure UFW
echo -e "${INFO}Installing UFW and configuring firewall rules...${NC}"
sudo apt install -y ufw
sudo ufw allow 22/tcp comment "SSH"
sudo ufw allow 5901/tcp comment "VNC Display 1"
sudo ufw enable

echo -e "${INFO}Adding the user $USER with the specified password...${NC}"
sudo useradd -m -s /bin/bash $USER
echo "$USER:$PASSWORD" | sudo chpasswd

echo -e "${INFO}Adding $USER to the sudo group...${NC}"
sudo usermod -aG sudo $USER

# Configure VNC for the user
echo -e "${INFO}Configuring VNC for user $USER...${NC}"

# Create VNC directory
sudo -u $USER mkdir -p /home/$USER/.vnc

# Create VNC startup script
sudo -u $USER tee /home/$USER/.vnc/xstartup > /dev/null <<EOL
#!/bin/bash
xrdb \$HOME/.Xresources
# Clipboard synchronization for copy/paste between Windows and Linux
autocutsel -fork
autocutsel -selection PRIMARY -fork
startxfce4 &
EOL

# Make startup script executable
sudo chmod +x /home/$USER/.vnc/xstartup

# Set VNC password
echo -e "${INFO}Setting VNC password for user $USER...${NC}"
echo -e "$VNC_PASSWORD\n$VNC_PASSWORD\nn" | sudo -u $USER vncpasswd

# Create VNC systemd service
echo -e "${INFO}Creating VNC systemd service...${NC}"
sudo tee /etc/systemd/system/vncserver@.service > /dev/null <<EOL
[Unit]
Description=Start TightVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=$USER
Group=$USER
WorkingDirectory=/home/$USER

PIDFile=/home/$USER/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1024x768 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOL

# Enable VNC service
echo -e "${INFO}Enabling VNC service for display :1...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable vncserver@1.service

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
echo -e "${SUCCESS}Installation complete. XFCE Desktop, VNC Server, AdsPower, and a desktop shortcut have been installed.${NC}"
echo -e "${INFO}You can now connect via VNC with the following details:${NC}"
echo -e "${INFO}IP ADDRESS: ${SUCCESS}$IP_ADDR${NC}"
echo -e "${INFO}VNC PORT: ${SUCCESS}5901${NC}"
echo -e "${INFO}VNC ADDRESS: ${SUCCESS}$IP_ADDR:5901${NC}"
echo -e "${INFO}USER: ${SUCCESS}$USER${NC}"
echo -e "${INFO}USER PASSWORD: ${SUCCESS}$PASSWORD${NC}"
echo -e "${INFO}VNC PASSWORD: ${SUCCESS}$VNC_PASSWORD${NC}"
echo ""
echo -e "${INFO}Connect using RealVNC Viewer or any VNC client to: ${SUCCESS}$IP_ADDR:5901${NC}"

# Start VNC service manually for immediate use
echo -e "${INFO}Starting VNC service...${NC}"
sudo systemctl start vncserver@1.service

# Check VNC service status
if sudo systemctl is-active --quiet vncserver@1.service; then
    echo -e "${SUCCESS}VNC service started successfully!${NC}"
else
    echo -e "${WARNING}VNC service may not have started. You can start it manually after reboot with:${NC}"
    echo -e "${WARNING}sudo systemctl start vncserver@1.service${NC}"
fi

# Restart the system
echo -e "${INFO}Rebooting system to apply all changes...${NC}"
sudo reboot
