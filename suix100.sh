#!/bin/bash
sudo apt update &> /dev/null
apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends tzdata git ca-certificates curl build-essential libssl-dev pkg-config libclang-dev cmake &> /dev/null

echo "Установка RUST" && sleep 1

sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

echo "Установка ноды" && sleep 1

cd $HOME
rm -rf /var/sui/db /var/sui/genesis.blob
systemctl stop sui-node.service
rm /usr/local/bin/sui*
mkdir -p /var/sui/db
git clone https://github.com/MystenLabs/sui.git
cd sui

echo "Еще немного настроить осталось" && sleep 1

git remote add upstream https://github.com/MystenLabs/sui
git fetch upstream
git checkout -B devnet --track upstream/devnet
cp crates/sui-config/data/fullnode-template.yaml /var/sui/fullnode.yaml
wget -P /var/sui https://github.com/MystenLabs/sui-genesis/raw/main/devnet/genesis.blob
cargo build -p sui-node --release
mv $HOME/sui/target/release/sui-node /usr/local/bin/

echo "И сервисники создать" && sleep 1

sed -i.bak "s/db-path:.*/db-path: \"\/var\/sui\/db\"/ ; s/genesis-file-location:.*/genesis-file-location: \"\/var\/sui\/genesis.blob\"/" /var/sui/fullnode.yaml
while true; do
    read -p "Открыть публичный доступ к API и метрикам ноды? [Y/n] " rmv
    rmv=${rmv,,}                                 
    case $rmv in
        [y]* )
        sed -i.bak "s/127.0.0.1/0.0.0.0/" /var/sui/fullnode.yaml
	    break;;
        [n]* ) break;;
        * ) echo "y/n и никак иначе ";;   
    esac
done

echo "[Unit]
Description=Sui Node

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/sui-node --config-path /var/sui/fullnode.yaml
Restart=always
RestartSec=120

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/sui-node.service

# Starting services
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable sui-node.service
sudo systemctl restart sui-node.service

echo "Установлено, запущено, работает." && sleep 1

echo -e "\e[1m\e[32mОстановить ноду: \e[0m" 
echo -e "\e[1m\e[39m    systemctl stop sui-node \n \e[0m" 

echo -e "\e[1m\e[32mЗапустить: \e[0m" 
echo -e "\e[1m\e[39m    systemctl start sui-node \n \e[0m" 

echo -e "\e[1m\e[32mПроверить логи: \e[0m" 
echo -e "\e[1m\e[39m    journalctl -u sui-node -f \n \e[0m" 
