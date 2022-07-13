#!/bin/bash

systemctl stop sui-node
systemctl disable sui-node
rm /etc/systemd/system/sui-node.service
rm -rf ~/sui /var/sui/

apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends tzdata git ca-certificates curl build-essential libssl-dev pkg-config libclang-dev cmake &> /dev/null
    
apt install cargo 
git clone https://github.com/MystenLabs/sui.git

cd sui
git remote add upstream https://github.com/MystenLabs/sui
git fetch upstream
git checkout --track upstream/devnet
cp crates/sui-config/data/fullnode-template.yaml fullnode.yaml
curl -fLJO https://github.com/MystenLabs/sui-genesis/raw/main/devnet/genesis.blob
screen -S 1
cargo run --release --bin sui-node -- --config-path fullnode.yaml
