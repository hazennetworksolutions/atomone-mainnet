<h1 align="center"> Atomone Testnet v4 Upgrade with Cosmovisor </h1>


```
mkdir -p $HOME/.atomone/cosmovisor/upgrades/v4/bin
wget https://github.com/atomone-hub/atomone/releases/download/v4.0.0-rc1/atomoned-v4.0.0-rc1-linux-amd64
mv atomoned-v4.0.0-rc1-linux-amd64 $HOME/.atomone/cosmovisor/upgrades/v4/bin/atomoned
chmod +x $HOME/.atomone/cosmovisor/upgrades/v4/bin/atomoned
```
```
sudo ln -sfn $HOME/.atomone/cosmovisor/upgrades/v4 $HOME/.atomone/cosmovisor/current
sudo ln -sfn $HOME/.atomone/cosmovisor/current/bin/atomoned /usr/local/bin/atomoned
sudo systemctl restart atomoned
```
