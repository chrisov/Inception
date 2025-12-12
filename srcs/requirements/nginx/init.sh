#!/bin/bash


set -e


# Create SSL certificate directory
mkdir -p /etc/nginx/ssl


# Generate self-signed SSL certificate for HTTPS
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/key.pem -out /etc/nginx/ssl/fullchain.pem \
	-subj "/C=DE/ST=BW/L=Heilbronn/O=42/OU=student/CN=${DOMAIN_NAME}"


# Configure nginx virtual host with SSL and PHP-FPM forwarding
cat > /etc/nginx/sites-available/default << EOF

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


# Enable the site configuration by creating symbolic link
ln -sf "/etc/nginx/sites-available/default" "/etc/nginx/sites-enabled/default"


# Start nginx in foreground mode (replaces shell process with PID 1)
exec nginx -g "daemon off;"