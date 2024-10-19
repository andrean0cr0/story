
#!/bin/bash

log() {
    echo -e "\e[1;32m$1\e[0m"
}

log "꧁IP꧂"

read -p "Enter the name of your node: " MONIKER_NAME

log "Step 1: Install dependencies..."
sudo apt update && sudo apt-get update && sudo apt install -y curl git make jq build-essential gcc unzip wget lz4 aria2 pv

log "Step 2: Downloading the Story-Geth binary..."
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.3-b224fdf.tar.gz
tar -xzvf geth-linux-amd64-0.9.3-b224fdf.tar.gz
mkdir -p $HOME/go/bin
grep -qxF 'export PATH=$PATH:/usr/local/go/bin:~/go/bin' ~/.bash_profile || echo 'export PATH=$PATH:/usr/local/go/bin:~/go/bin' >> ~/.bash_profile
sudo cp geth-linux-amd64-0.9.3-b224fdf/geth $HOME/go/bin/story-geth
source ~/.bash_profile

log "Step 3: Download Story binary..."
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.10.1-57567e5.tar.gz
tar -xzvf story-linux-amd64-0.10.1-57567e5.tar.gz
cp story-linux-amd64-0.10.1-57567e5/story $HOME/go/bin
source ~/.bash_profile

log "Step 4: Version Check..."
story-geth version
story version

log "Step 5: Initialize the node with the entered moniker \"$MONIKER_NAME\"..."
story init --network iliad --moniker "$MONIKER_NAME"

log "Step 6: Create a service file for story-geth..."
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

log "Step 7: Create a service file for the story..."
sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

log "Step 8: Using a snapshot to speed up synchronization..."
sudo systemctl stop story
sudo systemctl stop story-geth

log "Download and unzip the snapshots..."
cd $HOME
wget --show-progress https://josephtran.co/Story_snapshot.lz4
wget --show-progress https://josephtran.co/Geth_snapshot.lz4

cp ~/.story/story/data/priv_validator_state.json ~/.story/priv_validator_state.json.backup

rm -rf ~/.story/story/data
rm -rf ~/.story/geth/iliad/geth/chaindata

log "Unpacking the Story snapshot..."
sudo mkdir -p /root/.story/story/data
pv Story_snapshot.lz4 | lz4 -d -c | sudo tar xv -C ~/.story/story/ > /dev/null

log "Unpacking the Geth snapshot...."
sudo mkdir -p /root/.story/geth/iliad/geth/chaindata
pv Geth_snapshot.lz4 | lz4 -d -c | sudo tar xv -C ~/.story/geth/iliad/geth/ > /dev/null

cp ~/.story/priv_validator_state.json.backup ~/.story/story/data/priv_validator_state.json

log "Step 9: Restarting the services..."
sudo systemctl start story
sudo systemctl start story-geth

log "Step 10: Configure automatic restart of services..."
sudo systemctl daemon-reload
sudo systemctl enable story-geth
sudo systemctl enable story
sudo systemctl restart story-geth
sudo systemctl restart story

log "꧁IP꧂"
