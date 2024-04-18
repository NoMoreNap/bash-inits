#!/bin/sh

IP=$(echo $SSH_CONNECTION | awk '{print $1}')

echo "ваш IP-адрес: $IP"

sudo apt update

echo "installing node and npm"

sudo apt install nodejs npm -y


echo 'installing nfw'
sudo apt install ufw -y

echo 'configure nfw'
sudo ufw allow OpenSSH
sudo ufw allow 22
sudo ufw allow out 80/tcp && sudo ufw allow in 80/tcp
sudo ufw allow 443

echo "y" | sudo ufw enable
sudo ufw status

echo -e "\e[31mcheck OpenSSH and 80 port listener \e[0m"
echo "if all correctly press y if all right or n for exit and configure manually (y|n)"
read -p "ur choice (y/n): " choice
if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    echo 'y'
else
    sudo ufw disable
    kill $$
fi


echo "installing mongo"

sudo apt-get install gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

echo "starting mongo"

sudo systemctl start mongod

if systemctl is-active --quiet mongod; then
    echo "монго служба запущена"
else
    echo "монго служба не запущена, повторный перезаупск"
    sudo systemctl daemon-reload
    sudo systemctl start mongod
fi

if systemctl is-active --quiet mongod; then
  sudo systemctl status mongod
  sudo systemctl enable mongod
else
  echo "монго служба не запущена"
  kill $$
fi

echo "configure mongo for $IP"

port=$(ss -tlnp | grep mongo | awk '{print $4}' | awk -F ':' '{print $NF}')

echo "port of MongoDB: $port"

sudo ufw allow from $IP to any port $port


echo "update mongo configuration file for Mongo 6.0+"
{
  echo "storage:"
  echo "  dbPath: /var/lib/mongodb"
  echo ""
  echo "systemLog:"
  echo "  destination: file"
  echo "  logAppend: true"
  echo "  path: /var/log/mongodb/mongod.log"
  echo ""
  echo "net:"
  echo "  port: $port"
  echo "  bindIp: 0.0.0.0"
  echo ""
  echo "processManagement:"
  echo "  timeZoneInfo: /usr/share/zoneinfo"
} >/etc/mongod.conf

sudo systemctl restart mongod

echo "installing pm2"

npm i pm2 -g


echo "installing redis"

sudo apt install software-properties-common apt-transport-https curl ca-certificates -y
sudo apt install redis -y
sudo systemctl enable redis-server --now - y
systemctl status redis-server
echo 'ping' | redis-cli







