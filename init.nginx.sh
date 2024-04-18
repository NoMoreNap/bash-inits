#!/bin/sh

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \| sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \http://nginx.org/packages/debian `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \| sudo tee /etc/apt/preferences.d/99nginx
apt update

apt install nginx -y
sudo nginx -v
sudo systemctl start nginx

sudo systemctl enable nginx
