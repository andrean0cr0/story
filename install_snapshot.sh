
#!/bin/bash

log() {
    echo -e "\e[1;32m$1\e[0m"
}

log "SNAPSHOT"

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

log "DONE"
