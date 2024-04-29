#!/bin/sh



echo 'add sury PPA repository'

sudo apt update
sudo apt install lsb-release apt-transport-https ca-certificates software-properties-common -y

sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sudo sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
sudo apt update

echo 'install PHP 8.2 packages'

sudo apt install php8.2 -y
php -v

sh delete.apache.sh
sh init.nginx.sh


echo 'install PHP 8.2 extensions'
sudo apt install php8.2-{cli,zip,mysql,bz2,curl,mbstring,intl,common,mysqli} -y
# sudo apt install php8.2-<extension-name>

echo 'install fpm'
sudo apt install php8.2-fpm


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


echo 'installing mariadb'

sudo apt-get install mariadb-server
sudo mysql_secure_installation

echo 'installing phpmyadmin'
wget -P /var/www/Downloads https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
wget -P /var/www/Downloads https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
wget -P /var/www/Downloads https://files.phpmyadmin.net/phpmyadmin.keyring
cd /var/www/Downloads
gpg --import phpmyadmin.keyring
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz.asc
gpg --verify phpMyAdmin-latest-all-languages.tar.gz.asc
sudo mkdir /var/www/phpMyAdmin
sudo tar xvf phpMyAdmin-latest-all-languages.tar.gz --strip-components=1 -C /var/www/phpMyAdmin
sudo cp /var/www/phpMyAdmin/config.sample.inc.php /var/www/phpMyAdmin/config.inc.php
sudo chmod 660 /var/www/phpMyAdmin/config.inc.php
sudo chown -R www-data:www-data /var/www/phpMyAdmin

ip_address=$(ip addr show | grep -Eo 'inet ([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | awk '{print $2}')
echo "IP-адрес сервера: $ip_address"
echo 'test config'
touch /etc/nginx/sites-enabled/test.conf
{
      echo "server {"
      echo "  listen 80;"
      echo "  server_name $ip_address;"
      echo ""
      echo "  location /admin {"
      echo "    alias /var/www/phpMyAdmin/;"
      echo "    index index.php index.html index.htm;"
      echo ""
      echo "    location ~ \.php$ {"
      echo "     include snippets/fastcgi-php.conf;"
      echo "     fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;"
      echo '     fastcgi_param SCRIPT_FILENAME $request_filename;'
      echo "     include fastcgi_params;"
      echo "    }"
      echo ""
      echo "  }"
      echo ""
      echo "    location ~ /\.ht {"
      echo "     deny all;"
      echo "    }"
      echo "}"
} > /etc/nginx/sites-enabled/test.conf

sudo nginx -t
sudo systemctl restart nginx


echo "installing redis"

sudo apt install software-properties-common apt-transport-https curl ca-certificates -y
sudo apt install redis -y
sudo systemctl enable redis-server --now - y
systemctl status redis-server
echo 'ping' | redis-cli


