# User Documentation - Inception Project

Complete guide for installing, configuring, and using the Inception Docker infrastructure.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Starting Services](#starting-services)
5. [Accessing WordPress](#accessing-wordpress)
6. [Managing Services](#managing-services)
7. [WordPress Administration](#wordpress-administration)
8. [Troubleshooting](#troubleshooting)
9. [Backup and Restore](#backup-and-restore)

---

## Prerequisites

### System Requirements

**Minimum:**
- Virtual Machine with Linux (Ubuntu 20.04+ or Debian 11+)
- 2GB RAM
- 2 CPU cores
- 10GB free disk space

**Recommended:**
- 4GB RAM
- 4 CPU cores
- 20GB free disk space
- SSD storage

### Required Software

Before starting, ensure you have:

1. **Docker Engine** (v20.10 or later)
2. **Docker Compose** (v2.0 or later)
3. **Make** (build tool)
4. **Git** (for cloning repository)
5. **Root/sudo access**

### Installing Docker

If Docker is not installed:

```bash
# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# Install dependencies
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

---

## Installation

### Step 1: Clone Repository

```bash
cd ~
git clone https://github.com/chrisov/Inception.git
cd Inception
```

### Step 2: Create Data Directories

The project uses persistent volumes stored on the host:

```bash
# Create directories for persistent data
sudo mkdir -p /home/$USER/data/database
sudo mkdir -p /home/$USER/data/web

# Set correct ownership
sudo chown -R $USER:$USER /home/$USER/data
```

**Important:** If your username is different from `dchrysov`, update the volume paths:

```bash
# Edit docker-compose.yml to match your username
sed -i "s|/home/dchrysov|/home/$USER|g" srcs/docker-compose.yml
```

### Step 3: Verify Project Files

Ensure all required files exist:

```bash
ls -la srcs/
# Should show: docker-compose.yml, .env, requirements/

ls -la srcs/requirements/
# Should show: nginx/, wordpress/, mariadb/

ls -la srcs/requirements/*/Dockerfile
# Should show all three Dockerfiles
```

---

## Configuration

### Domain Name Setup

The project uses the domain `dchrysov.42.fr`. You need to configure it to point to your VM.

#### On the VM (where containers run):

```bash
# Back up hosts file
sudo cp /etc/hosts /etc/hosts.bak

# Add domain entry
echo "127.0.0.1 dchrysov.42.fr www.dchrysov.42.fr" | sudo tee -a /etc/hosts

# Verify
getent hosts dchrysov.42.fr
# Should output: 127.0.0.1  dchrysov.42.fr
```

#### On your host machine (to access from browser):

**Linux/Mac:**
```bash
# Get VM IP address (run on VM)
hostname -I | awk '{print $1}'

# On host machine, edit hosts file
sudo nano /etc/hosts

# Add line (replace <VM_IP> with actual IP):
<VM_IP>  dchrysov.42.fr www.dchrysov.42.fr
```

**Windows:**
```powershell
# Run Notepad as Administrator
notepad C:\Windows\System32\drivers\etc\hosts

# Add line:
<VM_IP>  dchrysov.42.fr www.dchrysov.42.fr
```

### Environment Variables

Edit the environment configuration file:

```bash
nano srcs/.env
```

**Critical: Change ALL passwords!**

```bash
# Domain (keep as is for 42 project)
DOMAIN_NAME=dchrysov.42.fr

# WordPress Site
WP_TITLE=inception
WP_URL=https://dchrysov.42.fr

# MySQL/MariaDB Configuration
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=your_secure_db_password          

# WordPress Admin User
WP_ADMIN_USER=youradminname
WP_ADMIN_PASSWORD=your_secure_admin_password    
WP_ADMIN_EMAIL=admin@dchrysov.42.fr

# WordPress Regular User
WP_USER=regularuser                              
WP_USER_PASSWORD=user_secure_password           
WP_USER_EMAIL=user@dchrysov.42.fr

# Database Connection (WordPress uses these)
DB_HOST=mariadb
DB_USER=wpuser
DB_PASSWORD=your_secure_db_password
DB_EMAIL=admin@dchrysov.42.fr
```

**Password Security Best Practices:**
- Use at least 12 characters
- Mix uppercase, lowercase, numbers, and special characters
- Avoid dictionary words
- Don't reuse passwords
- Never commit `.env` file with real passwords to Git

---

## Starting Services

### Pre-flight Checks

Before building, verify:

```bash
# Check Docker is running
docker info

# Check port 443 is available
sudo ss -tulpn | grep ':443'
# Should return nothing (port free)

# Check disk space
df -h
# Ensure at least 5GB free
```

### Build and Start

Use the Makefile to build and start all services:

```bash
# Build images and start containers
make build
```

This command will:
1. Create data directories (if not exists)
2. Build three Docker images (NGINX, WordPress, MariaDB)
3. Start all containers in detached mode
4. Set up networking and volumes

**Expected output:**
```
Building services...
[+] Building 45.2s (34/34) FINISHED
[+] Running 4/4
 ✔ Network inception_inception       Created
 ✔ Container mariadb                 Started
 ✔ Container wp-php                  Started
 ✔ Container nginx                   Started
```

**Build time:** First build takes 3-10 minutes depending on network speed.

### Monitor Initialization

Services need 30-60 seconds to initialize:

```bash
# Watch all logs in real-time
docker compose -f srcs/docker-compose.yml logs -f

# Or watch specific service
docker logs -f wp-php

# Wait for WordPress to show:
# "Database is ready"
# "Successfully created user: ..."
```

### Verify Deployment

```bash
# Check all containers are running
make status

# Or use Docker directly
docker ps
# Should show 3 running containers: nginx, wp-php, mariadb

# Check volumes
docker volume ls | grep inception
# Should show: inception_database, inception_web

# Check network
docker network ls | grep inception
# Should show: inception
```

---

## Accessing WordPress

### First Access

1. Open browser on your host machine
2. Navigate to: `https://dchrysov.42.fr`
3. **Certificate Warning**: 
   - Browser will show "Your connection is not private"
   - This is expected (self-signed certificate)
   - Click "Advanced" → "Proceed to dchrysov.42.fr (unsafe)"
4. You should see the WordPress homepage

### WordPress Admin Panel

Access the admin dashboard:

1. Navigate to: `https://dchrysov.42.fr/wp-admin`
2. Login with credentials from `.env`:
   - Username: Value of `WP_ADMIN_USER`
   - Password: Value of `WP_ADMIN_PASSWORD`
3. You'll see the WordPress dashboard

### Testing from Command Line

```bash
# Test HTTPS endpoint
curl -k https://dchrysov.42.fr
# Should return HTML content

# Test database connection
docker compose -f srcs/docker-compose.yml exec wordpress \
    wp db check --allow-root
# Output: Success: Database connection verified.

# Check WordPress version
docker compose -f srcs/docker-compose.yml exec wordpress \
    wp core version --allow-root
```

---

## Managing Services

### Common Operations

**Start services:**
```bash
make up
# Or: docker compose -f srcs/docker-compose.yml up -d
```

**Stop services:**
```bash
make down
# Or: docker compose -f srcs/docker-compose.yml down
```

**Restart services:**
```bash
make restart
# Or: make down && make up
```

**View logs:**
```bash
# Save logs to files
make logs
# Files created in logs/ directory

# View live logs
docker compose -f srcs/docker-compose.yml logs -f

# View specific service logs
docker logs nginx
docker logs wp-php
docker logs mariadb
```

**Check status:**
```bash
make status
# Shows containers, networks, volumes

docker ps
# Shows running containers

docker stats
# Shows resource usage
```

### Rebuilding Services

**Rebuild everything:**
```bash
make fclean    # Complete cleanup
make build     # Rebuild from scratch
```

**Rebuild specific service:**
```bash
docker compose -f srcs/docker-compose.yml up -d --build nginx
```

**Rebuild after changing Dockerfile:**
```bash
docker compose -f srcs/docker-compose.yml build --no-cache nginx
docker compose -f srcs/docker-compose.yml up -d nginx
```

### Accessing Container Shells

```bash
# Access WordPress container
docker exec -it wp-php bash

# Access NGINX container
docker exec -it nginx bash

# Access MariaDB container
docker exec -it mariadb bash

# Exit container
exit
```

### Running WordPress CLI Commands

```bash
# Check WordPress version
docker exec wp-php wp core version --allow-root

# List users
docker exec wp-php wp user list --allow-root

# Update WordPress
docker exec wp-php wp core update --allow-root

# Install plugin
docker exec wp-php wp plugin install akismet --activate --allow-root

# List plugins
docker exec wp-php wp plugin list --allow-root
```

---

## WordPress Administration

### Initial Setup

After first login to wp-admin:

1. **General Settings** (Settings → General):
   - Verify Site URL: `https://dchrysov.42.fr`
   - Set site tagline
   - Set timezone

2. **Permalink Settings** (Settings → Permalinks):
   - Select "Post name" for clean URLs
   - Save changes

3. **Discussion Settings** (Settings → Discussion):
   - Comment moderation is already enabled
   - Configure as needed

### User Management

The project creates two users automatically:
- **Admin user**: Specified in `WP_ADMIN_USER` (full access)
- **Regular user**: Specified in `WP_USER` (subscriber role)

**Adding more users:**

Via wp-admin:
1. Users → Add New
2. Fill in details
3. Select role (Editor, Author, Contributor, Subscriber)
4. Send email or set password

Via WP-CLI:
```bash
docker exec wp-php wp user create john john@example.com \
    --role=author --user_pass=securepass --allow-root
```

### Content Management

**Creating posts:**
1. Posts → Add New
2. Enter title and content
3. Select category/tags
4. Click "Publish"

**Creating pages:**
1. Pages → Add New
2. Enter title and content
3. Select template (if applicable)
4. Click "Publish"

**Managing media:**
1. Media → Library
2. Upload files (images, videos, documents)
3. Edit metadata as needed

### Theme Customization

**Change theme:**
1. Appearance → Themes
2. Add New or select installed theme
3. Click "Activate"

**Customize theme:**
1. Appearance → Customize
2. Modify colors, fonts, menus
3. Click "Publish"

### Plugin Management

**Install plugin:**
1. Plugins → Add New
2. Search for plugin
3. Click "Install Now"
4. Click "Activate"

**Via WP-CLI:**
```bash
docker exec wp-php wp plugin install contact-form-7 --activate --allow-root
```

---

## Troubleshooting

### Port 443 Permission Denied

**Problem:** Cannot bind to port 443 (rootless Docker)

**Solutions:**

**Option 1: Allow unprivileged port binding (kernel setting)**
```bash
# Temporary
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=443

# Persistent
echo 'net.ipv4.ip_unprivileged_port_start=443' | \
    sudo tee /etc/sysctl.d/99-rootless-ports.conf
sudo sysctl --system
```

**Option 2: Use different port**
```bash
# Edit docker-compose.yml
# Change ports from "443:443" to "8443:443"
# Access via: https://dchrysov.42.fr:8443
```

**Option 3: Run Docker as root**
```bash
sudo docker compose -f srcs/docker-compose.yml up -d
```

### Container Won't Start

**Check logs:**
```bash
docker logs mariadb
docker logs wp-php
docker logs nginx
```

**Common fixes:**

1. **Port already in use:**
```bash
sudo ss -tulpn | grep ':443'
# Kill process using port or change port mapping
```

2. **Volume permission issues:**
```bash
sudo chown -R $USER:$USER /home/$USER/data
```

3. **Out of disk space:**
```bash
df -h
# Clean up: make clean
```

### Database Connection Failed

**Problem:** WordPress can't connect to MariaDB

**Solutions:**

1. **Wait longer** (MariaDB takes time to initialize):
```bash
docker logs -f mariadb
# Wait for "ready for connections"
```

2. **Check environment variables:**
```bash
cat srcs/.env
# Ensure DB_PASSWORD matches MYSQL_PASSWORD
```

3. **Restart MariaDB:**
```bash
docker restart mariadb
docker restart wp-php
```

4. **Test connection:**
```bash
docker exec wp-php wp db check --allow-root
```

### Certificate/SSL Issues

**Problem:** Browser shows certificate error

**Solution:** This is expected with self-signed certificates. Click "Advanced" → "Proceed to site"

**For production:** Replace with CA-signed certificate:
1. Obtain certificate from Let's Encrypt or CA
2. Place `fullchain.pem` and `key.pem` in `srcs/certs/`
3. Update NGINX `init.sh` to use those files
4. Rebuild NGINX: `docker compose build nginx && docker compose up -d nginx`

### WordPress Shows Error

**Problem:** "Error establishing database connection"

**Check:**
```bash
# Verify MariaDB is running
docker ps | grep mariadb

# Check database logs
docker logs mariadb

# Verify credentials in .env match
cat srcs/.env | grep -E 'MYSQL|DB_'

# Test database access
docker exec mariadb mysql -u wpuser -p$MYSQL_PASSWORD wordpress -e "SHOW TABLES;"
```

### Slow Performance

**Solutions:**

1. **Increase PHP memory:**
```bash
docker exec wp-php sed -i 's/memory_limit = .*/memory_limit = 256M/' \
    /etc/php/8.2/fpm/php.ini
docker restart wp-php
```

2. **Check resource usage:**
```bash
docker stats
```

3. **Optimize MariaDB:**
```bash
docker exec mariadb mysqlcheck -u root -p$MYSQL_ROOT_PASSWORD --optimize --all-databases
```

### Domain Not Resolving

**Problem:** Can't access dchrysov.42.fr

**Solutions:**

1. **Check hosts file:**
```bash
# On VM:
getent hosts dchrysov.42.fr

# On host machine:
ping dchrysov.42.fr
```

2. **Flush DNS cache:**

Linux:
```bash
sudo systemd-resolve --flush-caches
```

Mac:
```bash
sudo dscacheutil -flushcache
```

Windows (PowerShell as Admin):
```powershell
ipconfig /flushdns
```

3. **Restart browser** or use incognito/private window

---

## Backup and Restore

### Creating Backups

**Manual backup:**

```bash
# Create backup directory
mkdir -p ~/inception-backups
cd ~/inception-backups

# Backup database
docker exec mariadb mysqldump -u root -prootpass wordpress \
    > db_backup_$(date +%Y%m%d).sql

# Backup WordPress files
sudo tar -czf web_backup_$(date +%Y%m%d).tar.gz /home/$USER/data/web

# Backup configuration
cp ~/Inception/srcs/.env env_backup_$(date +%Y%m%d)
```

**Automated backup script:**

```bash
cat > ~/backup-inception.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=~/inception-backups
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Get root password from .env
cd ~/Inception
source srcs/.env

# Backup database
docker exec mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD wordpress \
    > $BACKUP_DIR/db_$DATE.sql

# Backup files
sudo tar -czf $BACKUP_DIR/web_$DATE.tar.gz /home/$USER/data/web

# Backup config
cp srcs/.env $BACKUP_DIR/env_$DATE

echo "Backup completed: $DATE"
ls -lh $BACKUP_DIR/*$DATE*
EOF

chmod +x ~/backup-inception.sh

# Run backup
~/backup-inception.sh
```

**Schedule automatic backups (cron):**

```bash
# Edit crontab
crontab -e

# Add line (backup daily at 2 AM):
0 2 * * * /home/$USER/backup-inception.sh >> /home/$USER/backup.log 2>&1
```

### Restoring from Backup

**Restore database:**

```bash
# Stop services
make down

# Start only MariaDB
docker compose -f srcs/docker-compose.yml up -d mariadb

# Wait for MariaDB to be ready
sleep 10

# Restore database
docker exec -i mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD wordpress \
    < ~/inception-backups/db_backup_YYYYMMDD.sql

# Start all services
make up
```

**Restore WordPress files:**

```bash
# Stop services
make down

# Remove current files
sudo rm -rf /home/$USER/data/web/*

# Extract backup
sudo tar -xzf ~/inception-backups/web_backup_YYYYMMDD.tar.gz -C /

# Fix permissions
sudo chown -R www-data:www-data /home/$USER/data/web

# Start services
make up
```

**Complete restoration:**

```bash
make down
sudo rm -rf /home/$USER/data/*

# Restore files
sudo tar -xzf ~/inception-backups/web_backup_YYYYMMDD.tar.gz -C /
sudo chown -R www-data:www-data /home/$USER/data/web

# Restore database (after starting)
make up
sleep 15
docker exec -i mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD wordpress \
    < ~/inception-backups/db_backup_YYYYMMDD.sql
```

---

## Maintenance

### Regular Tasks

**Update WordPress:**
```bash
docker exec wp-php wp core update --allow-root
docker exec wp-php wp plugin update --all --allow-root
docker exec wp-php wp theme update --all --allow-root
```

**Check for issues:**
```bash
# Check site health
docker exec wp-php wp site health status --allow-root

# Verify database
docker exec wp-php wp db check --allow-root

# Check for broken links
docker exec wp-php wp link check --allow-root
```

**Clean up:**
```bash
# Clean WordPress cache
docker exec wp-php wp cache flush --allow-root

# Remove spam comments
docker exec wp-php wp comment delete $(wp comment list --status=spam --format=ids --allow-root) --allow-root

# Optimize database
docker exec mariadb mysqlcheck -u root -p$MYSQL_ROOT_PASSWORD --optimize wordpress
```

### Monitoring

**Check resource usage:**
```bash
docker stats --no-stream
```

**Check logs:**
```bash
make logs
tail -f logs/*.log
```

**Monitor disk space:**
```bash
df -h /home/$USER/data
```

---

## Quick Reference

### Essential Commands

```bash
# Start
make build        # First time
make up          # Subsequent starts

# Stop
make down

# Restart
make restart

# Logs
make logs        # Save to files
docker compose -f srcs/docker-compose.yml logs -f  # Live

# Status
make status

# Clean
make clean       # Keep data
make fclean      # Delete everything
```

### Access Points

- **WordPress Site:** https://dchrysov.42.fr
- **Admin Panel:** https://dchrysov.42.fr/wp-admin
- **Login:** Use credentials from `srcs/.env`

### Important Files

- `srcs/.env` - Configuration (passwords, domain)
- `srcs/docker-compose.yml` - Service definition
- `/home/dchrysov/data/` - Persistent data
- `Makefile` - Management commands

---

## Getting Help

If you encounter issues not covered here:

1. Check container logs: `docker logs <container_name>`
2. Review [DEV_DOC.md](DEV_DOC.md) for technical details
3. Verify all environment variables in `srcs/.env`
4. Ensure Docker and Docker Compose are up to date
5. Check port availability: `sudo ss -tulpn | grep 443`

---

*Last Updated: December 13, 2025*
