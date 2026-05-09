#linux-run.sh LINUX_USER_PASSWORD NGROK_AUTH_TOKEN LINUX_USERNAME LINUX_MACHINE_NAME
#!/bin/bash
# /home/runner/.ngrok2/ngrok.yml

sudo useradd -m $LINUX_USERNAME
sudo adduser $LINUX_USERNAME sudo
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
sudo hostname $LINUX_MACHINE_NAME

if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
  echo "Please set 'NGROK_AUTH_TOKEN'"
  exit 2
fi

if [[ -z "$LINUX_USER_PASSWORD" ]]; then
  echo "Please set 'LINUX_USER_PASSWORD' for user: $USER"
  exit 3
fi

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

mkdir test-repo
cd test-repo
wget https://static.rust-lang.org/dist/2026-05-09/rustc-nightly-x86_64-unknown-linux-gnu.tar.xz

git config --global user.name "Erfan Azari"
git config --global user.email "erfanazari31@outlook.com"

sudo apt install gh -y

echo "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" | gh auth login --with-token
gh auth setup-git

git init
git add .
git commit -m "Initial commit: downloaded file"

git branch -M main
git remote add origin https://github.com/erfanazari/test-repo.git
git push -u origin main

# ------------------------------------------------------------
# Download bore binary for Linux 386 (32-bit) from GitHub
# ------------------------------------------------------------
BORE_VERSION="v0.5.0"                     # latest stable as of writing
BORE_URL="https://github.com/ekzhang/bore/releases/download/${BORE_VERSION}/bore-${BORE_VERSION}-i686-unknown-linux-musl.tar.gz"

wget -q "$BORE_URL"
tar -xzf "bore-${BORE_VERSION}-i686-unknown-linux-musl.tar.gz"
chmod +x ./bore
rm "bore-${BORE_VERSION}-i686-unknown-linux-musl.tar.gz"   # optional cleanup

# ------------------------------------------------------------
# (Optional) Update user password – kept from your original script
# ------------------------------------------------------------
echo "### Update user: $USER password ###"
echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$USER"

# ------------------------------------------------------------
# Start bore tunnel for port 22 (SSH)
# ------------------------------------------------------------
echo "### Start bore proxy for 22 port ###"

rm -f .bore.log
# Bore writes its output (the public address) to stderr; redirect both stdout and stderr to log
./bore local 22 --to bore.pub > .bore.log 2>&1 &

sleep 5   # give it a moment to establish connection

# ------------------------------------------------------------
# Parse the public address from the log
# ------------------------------------------------------------
PUBLIC_ADDR=$(grep -o -E "bore.pub:[0-9]+" .bore.log | head -1)

if [[ -n "$PUBLIC_ADDR" ]]; then
  PORT=$(echo "$PUBLIC_ADDR" | cut -d':' -f2)
  echo ""
  echo "=========================================="
  echo "To connect: ssh $USER@bore.pub -p $PORT"
  echo "or connect with: ssh (Your Linux Username)@bore.pub -p $PORT"
  echo "=========================================="
else
  # Check for common errors (e.g., bore.pub unreachable, port conflict)
  echo "Failed to establish bore tunnel. Log output:"
  cat .bore.log
  exit 4
fi

# Keep the script running (or let it exit – bore runs in background)
# To keep the container/process alive, you might add: wait $!
