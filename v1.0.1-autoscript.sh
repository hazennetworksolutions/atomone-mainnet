#!/bin/bash
LOG_FILE="/var/log/atomone_node_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

printGreen() {
    echo -e "\033[32m$1\033[0m"
}

printLine() {
    echo "------------------------------"
}

# Function to print the node logo
function printNodeLogo {
    echo -e "\033[32m"
    echo "          
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
██████████████████████████████████████████████        ██████████████████████████████████████████████
███████████████████████████████████████████              ███████████████████████████████████████████
████████████████████████████████████████                    ████████████████████████████████████████
█████████████████████████████████████                          █████████████████████████████████████
█████████████████████████████████                                  █████████████████████████████████
██████████████████████████████             █             █            ██████████████████████████████
████████████████████████████           █████             ████           ████████████████████████████
████████████████████████████          ██████             ██████         ████████████████████████████
████████████████████████████          ██████             ██████          ███████████████████████████
████████████████████████████          ███████            ██████          ███████████████████████████
████████████████████████████          ██████████         ██████          ███████████████████████████
████████████████████████████          █████████████      ██████          ███████████████████████████
████████████████████████████             █████████████     ████          ███████████████████████████
████████████████████████████          █     █████████████     █          ███████████████████████████
████████████████████████████          █████     ████████████             ███████████████████████████
████████████████████████████          ██████       ████████████          ███████████████████████████
████████████████████████████          ██████          █████████          ███████████████████████████
████████████████████████████          ██████             ██████          ███████████████████████████
████████████████████████████          ██████             ██████          ███████████████████████████
████████████████████████████          ██████             ██████         ████████████████████████████
████████████████████████████            ████             ███            ████████████████████████████
██████████████████████████████                                        ██████████████████████████████
█████████████████████████████████                                  █████████████████████████████████
█████████████████████████████████████                           ████████████████████████████████████
████████████████████████████████████████                    ████████████████████████████████████████
███████████████████████████████████████████              ███████████████████████████████████████████
██████████████████████████████████████████████        ██████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████████████████████████
Hazen Network Solutions 2025 All rights reserved."
    echo -e "\033[0m"
}

# Show the node logo
printNodeLogo

# User confirmation to proceed
echo -n "Type 'yes' to start the installation Atomone Testnet v1.0.0 and press Enter: "
read user_input

if [[ "$user_input" != "yes" ]]; then
  echo "Installation cancelled."
  exit 1
fi

# Function to print in green
printGreen() {
  echo -e "\033[32m$1\033[0m"
}

printGreen "Starting installation..."
sleep 1

printGreen "If there are any, clean up the previous installation files"

sudo systemctl stop atomoned
sudo systemctl disable atomoned
sudo rm -rf /etc/systemd/system/atomoned.service
sudo rm $(which atomoned)
sudo rm -rf $HOME/.atomone
sed -i "/ATOMONE_/d" $HOME/.bash_profile

# Update packages and install dependencies
printGreen "1. Updating and installing dependencies..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

# User inputs
read -p "Enter your MONIKER: " MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (2-digit): " PORT
echo 'export PORT='$PORT

# Setting environment variables
echo "export MONIKER=$MONIKER" >> $HOME/.bash_profile
echo "export ATOMONE_CHAIN_ID=\"atomone-1"" >> $HOME/.bash_profile
echo "export ATOMONE_PORT=$PORT" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Chain ID:       \e[1m\e[32m$ATOMONE_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$ATOMONE_PORT\e[0m"
printLine
sleep 1

# Install Go
printGreen "2. Installing Go..." && sleep 1
cd $HOME
VER="1.21.13"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

# Version check
echo $(go version) && sleep 1

# Download Prysm protocol binary
printGreen "3. Downloading Atomone binary and setting up..." && sleep 1
cd $HOME
rm -rf atomone
git clone https://github.com/atomone-hub/atomone
cd atomone
git checkout v1.0.1
make build

mkdir -p ~/.atomone/cosmovisor/genesis/bin
mv $HOME/atomone/build/atomoned ~/.atomone/cosmovisor/genesis/bin/

sudo ln -s ~/.atomone/cosmovisor/genesis ~/.atomone/cosmovisor/current -f
sudo ln -s ~/.atomone/cosmovisor/current/bin/atomoned /usr/local/bin/atomoned -f

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.6.0

# Create service file
sudo tee /etc/systemd/system/atomoned.service > /dev/null << EOF
[Unit]
Description=atomone node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start --home $HOME/.atomone
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=${HOME}/.atomone"
Environment="DAEMON_NAME=atomoned"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:~/.atomone/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable atomoned

# Initialize the node
printGreen "7. Initializing the node..."
atomoned init $MONIKER --chain-id $ATOMONE_CHAIN_ID
sed -i \
-e "s/chain-id = .*/chain-id = \"atomone-1\"/" \
-e "s/keyring-backend = .*/keyring-backend = \"os\"/" \
-e "s/node = .*/node = \"tcp:\/\/localhost:${ATOMONE_PORT}657\"/" $HOME/.atomone/config/client.toml

# Download genesis and addrbook files
printGreen "8. Downloading genesis and addrbook..."
wget -O $HOME/.atomone/config/genesis.json https://server-7.itrocket.net/mainnet/atomone/genesis.json
wget -O $HOME/.atomone/config/addrbook.json  https://raw.githubusercontent.com/hazennetworksolutions/atomone-mainnet/refs/heads/main/addrbook.json


# Configure gas prices and ports
printGreen "9. Configuring custom ports and gas prices..." && sleep 1
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.001uatone"|g' $HOME/.atomone/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.atomone/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.atomone/config/config.toml

sed -i.bak -e "s%:1317%:${ATOMONE_PORT}317%g;
s%:8080%:${ATOMONE_PORT}080%g;
s%:9090%:${ATOMONE_PORT}090%g;
s%:9091%:${ATOMONE_PORT}091%g;
s%:8545%:${ATOMONE_PORT}545%g;
s%:8546%:${ATOMONE_PORT}546%g;
s%:6065%:${ATOMONE_PORT}065%g" $HOME/.atomone/config/app.toml

# Configure P2P and ports
sed -i.bak -e "s%:26658%:${ATOMONE_PORT}658%g;
s%:26657%:${ATOMONE_PORT}657%g;
s%:6060%:${ATOMONE_PORT}060%g;
s%:26656%:${ATOMONE_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ATOMONE_PORT}656\"%;
s%:26660%:${ATOMONE_PORT}660%g" $HOME/.atomone/config/config.toml

# Set up seeds and peers
printGreen "10. Setting up peers and seeds..." && sleep 1
SEEDS="f19d9e0f8d48119aa4cafde65de923ae2c29181a@atomone-mainnet-seed.itrocket.net:61656"
PEERS="ed0e36c57122184ab05b6c635b2f2adf592bfa0c@atomone-mainnet-peer.itrocket.net:61657,5d913650738a081aa02631a7f108dc7812330f0b@37.27.129.24:13656,2a3530e9778122cf9301fb034f6c92d9842049d3@46.166.143.72:26656,706a835221dcc171afa14429fac536d6b5a3736d@63.250.54.71:26656,4ef48d2cc03b332f9a711fc65dc0453839f9040d@8.52.153.92:61656,752bb5f1c914c5294e0844ddc908548115c1052c@65.108.236.5:14556,d3adcf9eee8665ee2d3108f721b3613cdd18c3a3@23.227.223.49:26656,8391dab9a9ece4e3f80e06512bdd1a84af5f257f@95.217.36.103:14556,61b7861a468dfa84532526afd98bea81bf41a874@121.78.247.244:16656,37201c92625df2814a55129f73f10ab6aa2edc35@185.16.39.137:27396"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.atomone/config/config.toml

# Pruning Settings
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.atomone/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.atomone/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.atomone/config/app.toml

# Download the snapshot
# printGreen "12. Downloading snapshot and starting node..." && sleep 1





# Start the node
printGreen "13. Starting the node..."
sudo systemctl start atomoned

# Check node status
printGreen "14. Checking node status..."
sudo journalctl -u atomoned -f -o cat

# Verify if the node is running
if systemctl is-active --quiet atomoned; then
  echo "The node is running successfully! Logs can be found at /var/log/atomone_node_install.log"
else
  echo "The node failed to start. Logs can be found at /var/log/atomone_node_install.log"
fi
