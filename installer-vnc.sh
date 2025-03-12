#!/bin/bash
# Kali Linux VNC Setup for Existing Desktop
# This script configures VNC to use your existing X session

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Kali Linux VNC Setup for Existing Desktop ===${NC}"

# Step 1: Check and install all required dependencies first
echo -e "${YELLOW}Step 1: Checking and installing required packages...${NC}"

# Create a function to check and install packages
install_if_missing() {
    for pkg in "$@"; do
        if ! command -v $pkg &> /dev/null; then
            echo -e "${YELLOW}Installing $pkg...${NC}"
            sudo apt update
            sudo apt install -y $pkg
            if ! command -v $pkg &> /dev/null; then
                echo -e "${RED}Failed to install $pkg. Please install it manually.${NC}"
                exit 1
            else
                echo -e "${GREEN}$pkg installed successfully.${NC}"
            fi
        else
            echo -e "${GREEN}$pkg is already installed.${NC}"
        fi
    done
}

# Check and install all required packages
install_if_missing x11vnc websockify

# Check for NoVNC installation
echo -e "${YELLOW}Checking for NoVNC installation...${NC}"
if [ -d "/usr/share/novnc" ]; then
    NOVNC_DIR="/usr/share/novnc"
    echo -e "${GREEN}NoVNC found at $NOVNC_DIR${NC}"
elif [ -d "/usr/share/javascript/novnc" ]; then
    NOVNC_DIR="/usr/share/javascript/novnc"
    echo -e "${GREEN}NoVNC found at $NOVNC_DIR${NC}"
else
    NOVNC_DIR=$(find /usr -name "novnc" -type d 2>/dev/null | head -n 1)
    if [ -z "$NOVNC_DIR" ]; then
        echo -e "${YELLOW}NoVNC not found. Installing...${NC}"
        sudo apt install -y novnc
        
        if [ -d "/usr/share/novnc" ]; then
            NOVNC_DIR="/usr/share/novnc"
            echo -e "${GREEN}NoVNC installed at $NOVNC_DIR${NC}"
        else
            NOVNC_DIR=$(find /usr -name "novnc" -type d 2>/dev/null | head -n 1)
            if [ -z "$NOVNC_DIR" ]; then
                echo -e "${RED}NoVNC installation failed. VNC server will work but web access will not be available.${NC}"
                SKIP_NOVNC=true
            else
                echo -e "${GREEN}NoVNC found at $NOVNC_DIR${NC}"
            fi
        fi
    else
        echo -e "${GREEN}NoVNC found at $NOVNC_DIR${NC}"
    fi
fi

# Step 2: Create directory for VNC password
echo -e "${YELLOW}Step 2: Setting up VNC password...${NC}"
mkdir -p ~/.vnc

# Step 3: Set VNC password - fixed method
if [ ! -f ~/.vnc/passwd ]; then
    # Direct method instead of piping with echo
    x11vnc -storepasswd ~/.vnc/passwd
else
    echo -e "${GREEN}VNC password already exists.${NC}"
    read -p "Reset password? (y/n): " RESET_PASS
    if [[ "$RESET_PASS" == "y" ]]; then
        x11vnc -storepasswd ~/.vnc/passwd
    fi
fi

# Step 4: Kill any existing VNC/websockify processes
echo -e "${YELLOW}Step 4: Killing any existing VNC/websockify processes...${NC}"
pkill -f x11vnc
pkill -f websockify
sleep 1

# Step 5: Get the current X display and authentication
echo -e "${YELLOW}Step 5: Detecting display and authentication...${NC}"

# Better display detection
if [ -z "$DISPLAY" ]; then
    # If DISPLAY is not set, try to find the active display
    DISPLAY=$(w -h $(whoami) | grep -oP ':[0-9]+(\.[0-9]+)?' | head -1)
    
    # If still not found, default to :0
    if [ -z "$DISPLAY" ]; then
        DISPLAY=":0"
    fi
fi

echo -e "${YELLOW}Current display is: $DISPLAY${NC}"

# Find the correct Xauthority file
if [ -f "$XAUTHORITY" ]; then
    AUTH_FILE="$XAUTHORITY"
elif [ -f "$HOME/.Xauthority" ]; then
    AUTH_FILE="$HOME/.Xauthority"
else
    # Try to find the auth file
    echo -e "${YELLOW}Searching for Xauthority file...${NC}"
    AUTH_FILE=$(find /run/user/$(id -u) -name "Xauthority" 2>/dev/null | head -1)
    
    if [ -z "$AUTH_FILE" ]; then
        # Last resort - try to find gdm auth files if running as root
        if [ $(id -u) -eq 0 ]; then
            AUTH_FILE=$(find /var/run/gdm* /var/lib/gdm* -name "*auth*" 2>/dev/null | head -1)
        fi
    fi
    
    if [ -z "$AUTH_FILE" ]; then
        echo -e "${YELLOW}No Xauthority file found, trying without specific auth...${NC}"
    else
        echo -e "${GREEN}Found auth file: $AUTH_FILE${NC}"
    fi
fi

# Step 6: Start x11vnc with the existing display and proper auth
echo -e "${YELLOW}Step 6: Starting x11vnc with your existing display...${NC}"

# Build the command based on available auth
VNC_CMD="x11vnc -display $DISPLAY -forever -shared -rfbauth ~/.vnc/passwd -rfbport 5900"

# Add auth file if found
if [ ! -z "$AUTH_FILE" ]; then
    VNC_CMD="$VNC_CMD -auth $AUTH_FILE"
fi

# Add additional options for better compatibility
VNC_CMD="$VNC_CMD -noxrecord -noxfixes -noxdamage -bg -o /tmp/x11vnc.log"

# Execute the command
echo -e "${YELLOW}Executing: $VNC_CMD${NC}"
eval $VNC_CMD

# Check if started successfully
sleep 2
if pgrep -f x11vnc > /dev/null; then
    echo -e "${GREEN}x11vnc started successfully on port 5900${NC}"
else
    echo -e "${RED}Failed to start x11vnc! Checking logs...${NC}"
    cat /tmp/x11vnc.log
    
    # Fallback with -auth guess if initial attempt failed
    echo -e "${YELLOW}Trying with auth guess option...${NC}"
    x11vnc -display $DISPLAY -forever -shared -rfbauth ~/.vnc/passwd -rfbport 5900 -auth guess -noxrecord -noxfixes -noxdamage -bg -o /tmp/x11vnc-fallback.log
    
    sleep 2
    if pgrep -f x11vnc > /dev/null; then
        echo -e "${GREEN}x11vnc started successfully with fallback method on port 5900${NC}"
    else
        echo -e "${RED}All attempts to start x11vnc failed! Checking fallback logs...${NC}"
        cat /tmp/x11vnc-fallback.log
        exit 1
    fi
fi

# Step 7: Start NoVNC web server
echo -e "${YELLOW}Step 7: Starting NoVNC web server...${NC}"

if [ "$SKIP_NOVNC" != "true" ]; then
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    # Start websockify
    echo -e "${YELLOW}Starting websockify on port 8080...${NC}"
    websockify --web=$NOVNC_DIR 8080 localhost:5900 &
    WEBSOCKIFY_PID=$!
    
    # Verify websockify is running
    sleep 2
    if ps -p $WEBSOCKIFY_PID > /dev/null; then
        echo -e "${GREEN}NoVNC websockify started successfully on port 8080${NC}"
    else
        echo -e "${RED}Failed to start websockify!${NC}"
        echo -e "${YELLOW}VNC server is still available at port 5900 without web interface.${NC}"
    fi
fi

# Create a startup script for future use
echo -e "${YELLOW}Creating startup script for future sessions...${NC}"
cat > ~/start-vnc.sh << EOF
#!/bin/bash
# Kill any existing processes
pkill -f x11vnc
pkill -f websockify
sleep 1

# Use the display that worked
DISPLAY="$DISPLAY"
# Start x11vnc with the auth option that worked
$VNC_CMD

if [ "$SKIP_NOVNC" != "true" ]; then
    # Start NoVNC
    websockify --web=$NOVNC_DIR 8080 localhost:5900 &
    echo "VNC server started on $SERVER_IP:5900"
    echo "Web access: http://$SERVER_IP:8080/vnc.html"
else
    echo "VNC server started on $SERVER_IP:5900"
    echo "Web access not available, use a VNC client"
fi
EOF
chmod +x ~/start-vnc.sh

# Final information
echo -e "\n${GREEN}=== SETUP COMPLETE ===${NC}"
echo -e "VNC server is running at: ${GREEN}$SERVER_IP:5900${NC}"

if [ "$SKIP_NOVNC" != "true" ]; then
    echo -e "Access via web browser at: ${GREEN}http://$SERVER_IP:8080/vnc.html${NC}"
fi

echo -e "Access with any VNC client at: ${GREEN}$SERVER_IP:5900${NC}"
echo -e "\nTo restart VNC in the future, simply run: ${GREEN}~/start-vnc.sh${NC}"
echo -e "To stop VNC: ${GREEN}pkill -f x11vnc${NC}"
