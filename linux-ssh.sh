#linux-run.sh LINUX_USER_PASSWORD NGROK_AUTH_TOKEN LINUX_USERNAME LINUX_MACHINE_NAME
#!/bin/bash
# /home/runner/.ngrok2/ngrok.yml

# sudo useradd -m $LINUX_USERNAME
# sudo adduser $LINUX_USERNAME sudo
# echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
# sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
# sudo hostname $LINUX_MACHINE_NAME

# if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
#   echo "Please set 'NGROK_AUTH_TOKEN'"
#   exit 2
# fi

# if [[ -z "$LINUX_USER_PASSWORD" ]]; then
#   echo "Please set 'LINUX_USER_PASSWORD' for user: $USER"
#   exit 3
# fi

# echo "### Install ngrok ###"

# # Download ngrok v3 for Linux 386 (32-bit)
# wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.zip
# unzip -o ngrok-v3-stable-linux-386.zip
# chmod +x ./ngrok

# echo "### Update user: $USER password ###"
# echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$USER"

# echo "### Start ngrok proxy for 22 port ###"


# rm -f .ngrok.log
# ./ngrok authtoken "$NGROK_AUTH_TOKEN"
# ./ngrok tcp 22 --log ".ngrok.log" &

# sleep 10
# HAS_ERRORS=$(grep "command failed" < .ngrok.log)

# if [[ -z "$HAS_ERRORS" ]]; then
#   echo ""
#   echo "=========================================="
#   echo "To connect: $(grep -o -E "tcp://(.+)" < .ngrok.log | sed "s/tcp:\/\//ssh $USER@/" | sed "s/:/ -p /")"
#   echo "or conenct with $(grep -o -E "tcp://(.+)" < .ngrok.log | sed "s/tcp:\/\//ssh (Your Linux Username)@/" | sed "s/:/ -p /")"
#   echo "=========================================="
# else
#   echo "$HAS_ERRORS"
#   exit 4
# fi

# mkdir test-repo
# cd test-repo
# wget https://static.rust-lang.org/dist/2026-05-09/rustc-nightly-x86_64-unknown-linux-gnu.tar.xz

# git config --global user.name "Erfan Azari"
# git config --global user.email "erfanazari31@outlook.com"

# echo "# Test Repo" > README.md
# git init
# git add .
# git commit -m "Initial commit"
# gh repo create erfanazari/test-repo --public --push --source . --remote origin

# git init
# git add .
# git commit -m "Initial commit: downloaded file"

# git branch -M main
# git remote add origin https://erfanazari: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@github.com/erfanazari/test-repo.git
# git push -u origin main

# ------------------------------------------------------------
# Download bore binary for Linux 386 (32-bit) from GitHub
# ------------------------------------------------------------
# BORE_VERSION="v0.5.0"                     # latest stable as of writing
# BORE_URL="https://github.com/ekzhang/bore/releases/download/${BORE_VERSION}/bore-${BORE_VERSION}-i686-unknown-linux-musl.tar.gz"

# wget -q "$BORE_URL"
# tar -xzf "bore-${BORE_VERSION}-i686-unknown-linux-musl.tar.gz"
# chmod +x ./bore
# rm "bore-${BORE_VERSION}-i686-unknown-linux-musl.tar.gz"   # optional cleanup

# # ------------------------------------------------------------
# # (Optional) Update user password – kept from your original script
# # ------------------------------------------------------------
# echo "### Update user: $USER password ###"
# echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$USER"

# # ------------------------------------------------------------
# # Start bore tunnel for port 22 (SSH)
# # ------------------------------------------------------------
# echo "### Start bore proxy for 22 port ###"

# rm -f .bore.log
# # Bore writes its output (the public address) to stderr; redirect both stdout and stderr to log
# ./bore local 22 --to bore.pub > .bore.log 2>&1 &

# sleep 5   # give it a moment to establish connection

# # ------------------------------------------------------------
# # Parse the public address from the log
# # ------------------------------------------------------------
# PUBLIC_ADDR=$(grep -o -E "bore.pub:[0-9]+" .bore.log | head -1)

# if [[ -n "$PUBLIC_ADDR" ]]; then
#   PORT=$(echo "$PUBLIC_ADDR" | cut -d':' -f2)
#   echo ""
#   echo "=========================================="
#   echo "To connect: ssh $USER@bore.pub -p $PORT"
#   echo "or connect with: ssh (Your Linux Username)@bore.pub -p $PORT"
#   echo "=========================================="
# else
#   # Check for common errors (e.g., bore.pub unreachable, port conflict)
#   echo "Failed to establish bore tunnel. Log output:"
#   cat .bore.log
#   exit 4
# fi

# Keep the script running (or let it exit – bore runs in background)
# To keep the container/process alive, you might add: wait $!

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (sudo).${NC}"
    exit 1
fi

# Get latest version
echo -e "${GREEN}Fetching latest GooseRelayVPN release...${NC}"
LATEST_VERSION=$(curl -s https://api.github.com/repos/kianmhz/GooseRelayVPN/releases/latest | grep '"tag_name"' | cut -d '"' -f4)
if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Failed to fetch latest version.${NC}"
    exit 1
fi
echo -e "Latest version: ${LATEST_VERSION}"

# Download
ARCH="linux-amd64"
DOWNLOAD_URL="https://github.com/kianmhz/GooseRelayVPN/releases/download/${LATEST_VERSION}/GooseRelayVPN-server-${LATEST_VERSION}-${ARCH}.tar.gz"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
echo -e "${GREEN}Downloading server...${NC}"
curl -L -o server.tar.gz "$DOWNLOAD_URL"
tar -xzf server.tar.gz

# Find the binary (it's inside a versioned directory)
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "GooseRelayVPN-server-*" | head -1)
if [ -z "$EXTRACTED_DIR" ]; then
    echo -e "${RED}Extraction failed – no directory found.${NC}"
    exit 1
fi
cd "$EXTRACTED_DIR"
if [ ! -f goose-server ]; then
    echo -e "${RED}goose-server binary not found in extracted files.${NC}"
    exit 1
fi
chmod +x goose-server
mv goose-server /usr/local/bin/
echo -e "${GREEN}Server binary installed to /usr/local/bin/goose-server${NC}"

# Generate tunnel key
TUNNEL_KEY=$(openssl rand -hex 32)
echo -e "${GREEN}Tunnel key: ${YELLOW}${TUNNEL_KEY}${NC}"

# Config
mkdir -p /etc/goose-relay
cat > /etc/goose-relay/server_config.json <<EOF
{
  "server_host": "0.0.0.0",
  "server_port": 8443,
  "tunnel_key": "${TUNNEL_KEY}"
}
EOF

# Firewall
if command -v ufw &> /dev/null; then
    ufw allow 8443/tcp
fi

# systemd service
cat > /etc/systemd/system/goose-relay.service <<EOF
[Unit]
Description=GooseRelayVPN exit server
After=network.target

[Service]
Type=simple
WorkingDirectory=/etc/goose-relay
ExecStart=/usr/local/bin/goose-server -config /etc/goose-relay/server_config.json
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable goose-relay
systemctl start goose-relay
systemctl status goose-relay
journalctl -u goose-relay.service -n 50 --no-pager
echo -e "${GREEN}goose-server service started and enabled.${NC}"

# Health check
sleep 2
if systemctl is-active --quiet goose-relay; then
    echo -e "${GREEN}goose-server is running.${NC}"
    curl -s http://127.0.0.1:8443/healthz || echo -e "${YELLOW}Health endpoint not responding yet, but service is active.${NC}"
else
    echo -e "${RED}goose-server service failed to start. Check 'systemctl status goose-relay'.${NC}"
    exit 1
fi

# Ask about tunnel (bore/ngrok)
echo ""
echo -e "${YELLOW}Since this server may not have a public IP, you need a tunnel to expose port 8443.${NC}"
echo "Options:"
echo "  1) bore (free, no account, runs in background)"
echo "  2) ngrok (requires auth token, manual setup)"
echo "  3) Skip (you will set up your own tunnel later)"
# read -p "Choose [1/2/3]: " tunnel_choice
tunnel_choice="1"
echo "  Default is 1 for bore."

if [ "$tunnel_choice" = "1" ]; then
    # Install bore
    if ! command -v bore &> /dev/null; then
        echo -e "${GREEN}Installing bore...${NC}"
        # Download prebuilt bore binary for linux-amd64
        BORE_URL="https://github.com/ekzhang/bore/releases/download/v0.5.0/bore-v0.5.0-x86_64-unknown-linux-musl.tar.gz"
        curl -L "$BORE_URL" | tar -xz -C /usr/local/bin bore
        chmod +x /usr/local/bin/bore
    fi
    # Start bore in background using nohup
    mkdir -p /var/log/bore
    nohup /usr/local/bin/bore local 8443 --to bore.pub > /var/log/bore/bore.log 2>&1 &
    BORE_PID=$!
    echo $BORE_PID > /var/run/bore.pid
    echo -e "${GREEN}bore started (PID $BORE_PID). Logs: /var/log/bore/bore.log${NC}"
    echo -e "${YELLOW}Waiting for bore to print public URL...${NC}"
    sleep 3
    # Extract URL from log
    PUBLIC_URL=$(grep -o 'https\?://[a-zA-Z0-9.-]*\.bore\.pub:[0-9]*' /var/log/bore/bore.log | head -1)
    if [ -z "$PUBLIC_URL" ]; then
        PUBLIC_URL="(check /var/log/bore/bore.log for the URL after a few seconds)"
    fi
    echo -e "${GREEN}Your public bore tunnel URL: ${YELLOW}${PUBLIC_URL}${NC}"
    sleep 10s
    cat /var/log/bore/bore.log
    echo -e "You will use this URL (without trailing slash) as the VPS_URL in Google Apps Script (Code.gs)."
    # Optional: create a systemd service for bore (commented)
    # ...
elif [ "$tunnel_choice" = "2" ]; then
    echo -e "${YELLOW}ngrok setup:${NC}"
    echo "1. Sign up at https://ngrok.com and get your auth token."
    echo "2. Install ngrok: https://ngrok.com/download"
    echo "3. Run: ngrok config add-authtoken <YOUR_TOKEN>"
    echo "4. Then run: ngrok http 8443"
    echo "5. Use the forwarding https URL as VPS_URL in Apps Script."
elif [ "$tunnel_choice" = "3" ]; then
    echo -e "${YELLOW}Skipping tunnel setup. You must expose port 8443 yourself.${NC}"
fi

# Final output
echo ""
echo -e "${GREEN}========== Server Setup Complete ==========${NC}"
echo -e "Tunnel key (copy this for your client config): ${YELLOW}${TUNNEL_KEY}${NC}"
if [ "$tunnel_choice" = "1" ]; then
    echo -e "Public URL for Apps Script (VPS_URL): ${YELLOW}${PUBLIC_URL}${NC}"
fi
echo ""
echo -e "Next steps on the client (Windows/macOS/Linux):"
echo "  1. Set 'tunnel_key' to the above value in client_config.json"
echo "  2. Deploy Code.gs to Google Apps Script and set VPS_URL to your public URL"
echo "  3. Add the Deployment ID(s) to 'script_keys' in client_config.json"
echo "  4. Run goose-client"
echo ""
echo -e "${GREEN}Systemd service for goose-server is installed and running.${NC}"
echo "   Start/stop: systemctl start/stop goose-relay"
echo "   Status: systemctl status goose-relay"
echo "   Logs: journalctl -u goose-relay -f"
if [ "$tunnel_choice" = "1" ]; then
    echo ""
    echo "bore is running in the background (PID $BORE_PID)."
    echo "  To stop bore: kill $(cat /var/run/bore.pid 2>/dev/null)"
    echo "  Logs: tail -f /var/log/bore/bore.log"
fi
