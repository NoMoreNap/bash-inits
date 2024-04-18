#!/bin/sh

EMAIL="$1"
DOMAIN="$2"

echo "running the proxy setup script"

echo "updating packages"
apt update
apt upgrade -y

echo "installing certbot"
add-apt-repository ppa:certbot/certbot -y
apt-get update
apt install certbot python3-certbot-nginx -y

echo "update default nginx configuration file"
{
    echo "server {"
    echo "  listen 80;"
    echo "  server_name _;"
    echo "  location ^~ /.well-known/acme-challenge/ {"
    echo "      default_type "text/plain";"
    echo "      root         /var/www/html;"
    echo "      break;"
    echo "  }"
    echo "  location = /.well-known/acme-challenge/ {"
    echo "      return 404;"
    echo "  }"
    echo "  location / {"
    echo "    return 301 https://\$host\$request_uri;"
    echo "  }"
    echo "}"
} >/etc/nginx/sites-enabled/default

echo "creating nginx configuration file"
{
    echo "server {"
    echo "  listen 80;"
    echo "  server_name $DOMAIN;"
    echo "}"
} >/etc/nginx/sites-enabled/$DOMAIN.conf

echo "start nginx"
systemctl start nginx

echo "checkout DNS"
while true; do
    result=$(dig +short $DOMAIN)
    current_ip=$(wget -O - -q ipv4.icanhazip.com)

    match=0
    for ip in $result; do
        if [ $ip = $current_ip ]; then
            match=1
            break
        fi
    done

    if [ $match = 1 ]; then
        break
    fi

    echo "the corresponding DNS record could not be found. Checked again in 10 seconds..."
    sleep 10
done

echo "creating ssl certificate with Certbot"
certbot certonly --nginx  -n -d $DOMAIN --agree-tos --email $EMAIL

echo "update nginx configuration file"
{
    echo "limit_conn_zone \$binary_remote_addr zone=conn_user:10m;"
    echo "limit_conn_zone \$server_name zone=conn_global:10m;"
    echo ""
    echo "limit_req_zone \$binary_remote_addr zone=req_user:10m rate=50r/s;"
    echo "limit_req_zone \$server_name zone=req_global:10m rate=20000r/s;"
    echo ""
    echo "server {"
    echo "  listen 80;"
    echo "  server_name $DOMAIN;"
    echo ""
    echo "  if (\$host = $DOMAIN) {"
    echo "    return 301 https://\$host\$request_uri;"
    echo "  }"
    echo ""
    echo "  return 404;"
    echo "}"
    echo ""
    echo "server {"
    echo "  listen 443 ssl;"
    echo "  server_name $DOMAIN;"
    echo ""
    echo "  ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;"
    echo "  ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;"
    echo "  include /etc/letsencrypt/options-ssl-nginx.conf;"
    echo "  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;"
    echo ""
    echo "  limit_conn conn_user 10;"
    echo "  limit_conn conn_global 20000;"
    echo ""
    echo "  limit_req zone=req_user burst=100;"
    echo "  limit_req zone=req_global burst=40000;"
    echo ""
    echo "  location / {"
    echo "  }"
    echo ""
    echo "}"
} >/etc/nginx/sites-enabled/$DOMAIN.conf

echo "restart nginx..."
systemctl restart nginx

echo "creating cron file..."
echo "15 3 * * * /usr/bin/certbot renew --quiet" >/etc/cron.d/letsencrypt_renew
chown root:root /etc/cron.d/letsencrypt_renew
chmod 0644 /etc/cron.d/letsencrypt_renew
