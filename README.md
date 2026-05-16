<div align="center">

# ⚛️ AtomOne Mainnet Full Node & Validator Setup Guide

**A complete guide to running an AtomOne mainnet full node and registering as a validator**  
*System preparation, binary installation, Cosmovisor setup, and validator creation — step by step.*

[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04+-E95420?style=flat-square&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![AtomOne](https://img.shields.io/badge/AtomOne-Mainnet-6B7CFF?style=flat-square)](https://atom.one)
[![Version](https://img.shields.io/badge/Node%20Version-v4.0.0-brightgreen?style=flat-square)](https://github.com/atomone-hub/atomone/releases)
[![Chain ID](https://img.shields.io/badge/Chain%20ID-atomone--1-blue?style=flat-square)](https://docs.atom.one)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

[hazennetworksolutions.com](https://hazennetworksolutions.com)

</div>

---

> **Network:** AtomOne Mainnet (Chain ID: atomone-1)  
> **Version:** v4.0.0  
> **Last Updated:** May 2026

---

## Table of Contents

- [Hardware Requirements](#hardware-requirements)
- [Step 1 — System Verification](#step-1--system-verification)
- [Step 2 — System Update and Dependencies](#step-2--system-update-and-dependencies)
- [Step 3 — Install Go](#step-3--install-go)
- [Step 4 — Download and Build Binary](#step-4--download-and-build-binary)
- [Step 5 — Install Cosmovisor](#step-5--install-cosmovisor)
- [Step 6 — Create Systemd Service](#step-6--create-systemd-service)
- [Step 7 — Initialize the Node](#step-7--initialize-the-node)
- [Step 8 — Download Genesis and Addrbook](#step-8--download-genesis-and-addrbook)
- [Step 9 — Configure Ports, Gas Prices and Pruning](#step-9--configure-ports-gas-prices-and-pruning)
- [Step 10 — Configure Seeds and Peers](#step-10--configure-seeds-and-peers)
- [Step 11 — Start the Node](#step-11--start-the-node)
- [Step 12 — Create a Wallet](#step-12--create-a-wallet)
- [Step 13 — Register as a Validator](#step-13--register-as-a-validator)
- [Monitoring the Node](#monitoring-the-node)
- [Useful Commands](#useful-commands)
- [Staying Updated](#staying-updated)

---

## Hardware Requirements

| Component | Minimum | Recommended |
|---|---|---|
| Operating System | Ubuntu 22.04+ | Ubuntu 24.04 |
| CPU | 4 cores | 8 cores |
| RAM | 16 GB | 32 GB |
| Disk | 500 GB NVMe SSD | 2 TB NVMe SSD |
| Network | 100 Mbps | 1 Gbps |

> ⚠️ Disk usage grows over time. Plan for long-term storage growth if running an archival node.

---

## Step 1 — System Verification

After SSH-ing into your server, verify the system meets requirements:

```bash
lsb_release -a          # Should be Ubuntu 22.04 or higher
uname -r                # Kernel version
lscpu | grep -E "Model name|CPU\(s\)|Thread|Socket|Core"
free -h                 # Minimum 16 GB RAM
df -h                   # Minimum 500 GB free disk
```

---

## Step 2 — System Update and Dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git wget htop tmux build-essential jq make lz4 gcc unzip
```

---

## Step 3 — Install Go

AtomOne v4.0.0 requires **Go 1.22+**:

```bash
cd $HOME
VER="1.22.10"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"

echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin
```

Verify the installation:

```bash
go version
```

Expected output: `go version go1.22.10 linux/amd64`

---

## Step 4 — Download and Build Binary

```bash
cd $HOME
rm -rf atomone
git clone https://github.com/atomone-hub/atomone
cd atomone
git checkout v4.0.0
make build

mkdir -p $HOME/.atomone/cosmovisor/genesis/bin
mv build/atomoned $HOME/.atomone/cosmovisor/genesis/bin/
rm -rf build

ln -s $HOME/.atomone/cosmovisor/genesis $HOME/.atomone/cosmovisor/current -f
sudo ln -s $HOME/.atomone/cosmovisor/current/bin/atomoned /usr/local/bin/atomoned -f
```

Verify:

```bash
atomoned version
```

Expected output: `v4.0.0`

> **Alternatively**, download the pre-built binary directly:
> ```bash
> wget -O atomoned https://github.com/atomone-hub/atomone/releases/download/v4.0.0/atomoned-v4.0.0-linux-amd64
> chmod +x atomoned
> mkdir -p $HOME/.atomone/cosmovisor/genesis/bin
> mv atomoned $HOME/.atomone/cosmovisor/genesis/bin/
> ln -s $HOME/.atomone/cosmovisor/genesis $HOME/.atomone/cosmovisor/current -f
> sudo ln -s $HOME/.atomone/cosmovisor/current/bin/atomoned /usr/local/bin/atomoned -f
> ```

---

## Step 5 — Install Cosmovisor

Cosmovisor handles automatic binary upgrades:

```bash
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.6.0
```

Verify:

```bash
cosmovisor version
```

---

## Step 6 — Create Systemd Service

Set your moniker and port prefix before creating the service:

```bash
MONIKER="YOUR_MONIKER"
PORT="26"   # Default is 26. Change to avoid conflicts (e.g. 27, 28...)
```

Create the service file:

```bash
sudo tee /etc/systemd/system/atomoned.service > /dev/null << EOF
[Unit]
Description=AtomOne Node Service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start --home $HOME/.atomone
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.atomone"
Environment="DAEMON_NAME=atomoned"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.atomone/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable atomoned
```

---

## Step 7 — Initialize the Node

```bash
atomoned config set client chain-id atomone-1
atomoned config set client keyring-backend os
atomoned config set client node tcp://localhost:${PORT}657

atomoned init $MONIKER --chain-id atomone-1
```

Set environment variables permanently:

```bash
echo "export MONIKER=$MONIKER" >> $HOME/.bash_profile
echo "export ATOMONE_CHAIN_ID=\"atomone-1\"" >> $HOME/.bash_profile
echo "export ATOMONE_PORT=$PORT" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

---

## Step 8 — Download Genesis and Addrbook

```bash
wget -O $HOME/.atomone/config/genesis.json \
  https://atomone.fra1.digitaloceanspaces.com/atomone-1/genesis.json

wget -O $HOME/.atomone/config/addrbook.json \
  https://raw.githubusercontent.com/hazennetworksolutions/atomone-mainnet/refs/heads/main/addrbook.json
```

Verify genesis checksum:

```bash
sha256sum $HOME/.atomone/config/genesis.json
```

---

## Step 9 — Configure Ports, Gas Prices and Pruning

### Custom Ports

If you changed the default port prefix, apply it here:

```bash
sed -i.bak -e "s%:1317%:${ATOMONE_PORT}317%g;
s%:8080%:${ATOMONE_PORT}080%g;
s%:9090%:${ATOMONE_PORT}090%g;
s%:9091%:${ATOMONE_PORT}091%g" $HOME/.atomone/config/app.toml

sed -i.bak -e "s%:26658%:${ATOMONE_PORT}658%g;
s%:26657%:${ATOMONE_PORT}657%g;
s%:6060%:${ATOMONE_PORT}060%g;
s%:26656%:${ATOMONE_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ATOMONE_PORT}656\"%;
s%:26660%:${ATOMONE_PORT}660%g" $HOME/.atomone/config/config.toml
```

### Gas Prices

```bash
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.025uatone,0.025uphoton"|g' \
  $HOME/.atomone/config/app.toml
```

### Pruning

```bash
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.atomone/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.atomone/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.atomone/config/app.toml
```

### Enable Prometheus (optional)

```bash
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.atomone/config/config.toml
```

### Disable Indexer (saves disk space)

```bash
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.atomone/config/config.toml
```

---

## Step 10 — Configure Seeds and Peers

```bash
SEEDS="f19d9e0f8d48119aa4cafde65de923ae2c29181a@atomone-mainnet-seed.itrocket.net:61656"
PEERS="ed0e36c57122184ab05b6c635b2f2adf592bfa0c@atomone-mainnet-peer.itrocket.net:61657,5d913650738a081aa02631a7f108dc7812330f0b@37.27.129.24:13656,2a3530e9778122cf9301fb034f6c92d9842049d3@46.166.143.72:26656,706a835221dcc171afa14429fac536d6b5a3736d@63.250.54.71:26656,4ef48d2cc03b332f9a711fc65dc0453839f9040d@8.52.153.92:61656,752bb5f1c914c5294e0844ddc908548115c1052c@65.108.236.5:14556,d3adcf9eee8665ee2d3108f721b3613cdd18c3a3@23.227.223.49:26656,8391dab9a9ece4e3f80e06512bdd1a84af5f257f@95.217.36.103:14556,61b7861a468dfa84532526afd98bea81bf41a874@121.78.247.244:16656,37201c92625df2814a55129f73f10ab6aa2edc35@185.16.39.137:27396"

sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.atomone/config/config.toml
```

---

## Step 11 — Start the Node

```bash
sudo systemctl start atomoned
sudo journalctl -u atomoned -f --no-pager -o cat
```

Verify the service is running:

```bash
sudo systemctl status atomoned --no-pager
```

The service should show `active (running)`.

Check sync status:

```bash
atomoned status 2>&1 | jq .SyncInfo
```

Wait until `catching_up` is `false` before proceeding to validator registration.

---

## Step 12 — Create a Wallet

```bash
atomoned keys add wallet
```

> ⚠️ **CRITICAL:** Save your mnemonic phrase in a secure location. Without it, you cannot recover your wallet.

To recover an existing wallet:

```bash
atomoned keys add wallet --recover
```

Check your balance:

```bash
atomoned query bank balances $(atomoned keys show wallet -a)
```

---

## Step 13 — Register as a Validator

> ⚠️ The node must be **fully synced** and you must have **ATONE tokens** before creating a validator.

### Get your pubkey:

```bash
atomoned comet show-validator
```

### Create validator JSON:

```bash
cat > $HOME/validator.json << EOF
{
  "pubkey": $(atomoned comet show-validator),
  "amount": "1000000uatone",
  "moniker": "YOUR_MONIKER",
  "identity": "",
  "website": "",
  "security": "",
  "details": "",
  "commission-rate": "0.05",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF
```

### Submit the transaction:

```bash
atomoned tx staking create-validator $HOME/validator.json \
  --from wallet \
  --chain-id atomone-1 \
  --gas auto \
  --gas-adjustment 1.4 \
  --fees 500uatone \
  -y
```

### Verify your validator:

```bash
atomoned query staking validator $(atomoned keys show wallet --bech val -a)
```

---

## Monitoring the Node

### Watch live block commits:

```bash
sudo journalctl -u atomoned -f --no-pager | grep "committed block"
```

### Full logs:

```bash
sudo journalctl -u atomoned -f --no-pager
```

### Sync status:

```bash
atomoned status 2>&1 | jq .SyncInfo
```

### Service management:

```bash
# Restart service
sudo systemctl restart atomoned

# Stop service
sudo systemctl stop atomoned

# Check status
sudo systemctl status atomoned
```

---

## Useful Commands

### Wallet

```bash
# List wallets
atomoned keys list

# Show wallet address
atomoned keys show wallet -a

# Check balance
atomoned query bank balances $(atomoned keys show wallet -a)
```

### Staking

```bash
# Delegate tokens
atomoned tx staking delegate $(atomoned keys show wallet --bech val -a) 1000000uatone \
  --from wallet --chain-id atomone-1 --gas auto --gas-adjustment 1.4 --fees 500uatone -y

# Redelegate tokens
atomoned tx staking redelegate $(atomoned keys show wallet --bech val -a) <NEW_VALOPER> 1000000uatone \
  --from wallet --chain-id atomone-1 --gas auto --gas-adjustment 1.4 --fees 500uatone -y

# Undelegate tokens
atomoned tx staking unbond $(atomoned keys show wallet --bech val -a) 1000000uatone \
  --from wallet --chain-id atomone-1 --gas auto --gas-adjustment 1.4 --fees 500uatone -y
```

### Rewards

```bash
# Withdraw all rewards
atomoned tx distribution withdraw-all-rewards \
  --from wallet --chain-id atomone-1 --gas auto --gas-adjustment 1.4 --fees 500uatone -y

# Withdraw commission
atomoned tx distribution withdraw-rewards $(atomoned keys show wallet --bech val -a) --commission \
  --from wallet --chain-id atomone-1 --gas auto --gas-adjustment 1.4 --fees 500uatone -y
```

### Governance

```bash
# List proposals
atomoned query gov proposals

# Vote on a proposal
atomoned tx gov vote 1 yes \
  --from wallet --chain-id atomone-1 --gas auto --gas-adjustment 1.4 --fees 500uatone -y
```

### Validator Operations

```bash
# Edit validator
atomoned tx staking edit-validator \
  --new-moniker "NEW_MONIKER" \
  --identity "" \
  --from wallet --chain-id atomone-1 --gas auto --gas-adjustment 1.4 --fees 500uatone -y

# Unjail validator
atomoned tx slashing unjail \
  --from wallet --chain-id atomone-1 --gas auto --gas-adjustment 1.4 --fees 500uatone -y

# Check validator signing info
atomoned query slashing signing-info $(atomoned comet show-validator)
```

---

## Staying Updated

Follow these channels to stay informed about upgrades and announcements:

- Discord: [AtomOne Developer Discord](https://discord.gg/atomone)
- GitHub Releases: [atomone-hub/atomone Releases](https://github.com/atomone-hub/atomone/releases)
- Official Docs: [docs.atom.one](https://docs.atom.one/guides/node-guide/)

### Upgrade with Cosmovisor (example: v5.0.0)

```bash
mkdir -p $HOME/.atomone/cosmovisor/upgrades/v5/bin
wget -O $HOME/.atomone/cosmovisor/upgrades/v5/bin/atomoned \
  https://github.com/atomone-hub/atomone/releases/download/v5.0.0/atomoned-v5.0.0-linux-amd64
chmod +x $HOME/.atomone/cosmovisor/upgrades/v5/bin/atomoned
```

Cosmovisor will automatically switch to the new binary at the upgrade block height.

---

*Guide maintained by [HazenNetworkSolutions](https://hazennetworksolutions.com)*
