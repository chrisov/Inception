#!/bin/bash

set -e

mkdir -p /etc/nginx/ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/key.pem -out /etc/nginx/ssl/fullchain.pem \
	-subj "/C=DE/ST=BW/L=Heilbronn/O=42/OU=student/CN=${DOMAIN_NAME}"

cat > /etc/nginx/sites-available/default << EOF

server {
	listen 80;
	listen [::]:80;
	server_name "${DOMAIN_NAME}" www."${DOMAIN_NAME}";
	return 301 https://\$host\$request_uri;
}

server {
	listen 443 ssl;
	listen [::]:443 ssl;
	server_name "${DOMAIN_NAME}" www."${DOMAIN_NAME}";

	root /var/www/html;
	index index.php;

	ssl_certificate /etc/nginx/ssl/fullchain.pem;
	ssl_certificate_key /etc/nginx/ssl/key.pem;
	ssl_protocols TLSv1.3;

	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass wordpress:9000;
	}
}
EOF

ln -sf "/etc/nginx/sites-available/default" "/etc/nginx/sites-enabled/default"

exec nginx -g "daemon off;"