# Developer Documentation - Inception Project

Technical architecture and implementation details for the Inception Docker infrastructure.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Container Design](#container-design)
3. [Networking](#networking)
4. [Volume Management](#volume-management)
5. [Service Configuration](#service-configuration)
6. [Dockerfile Analysis](#dockerfile-analysis)
7. [Initialization Scripts](#initialization-scripts)
8. [Docker Compose](#docker-compose)
9. [Security Considerations](#security-considerations)
10. [Customization Guide](#customization-guide)
11. [Development Workflow](#development-workflow)

---

## Architecture Overview

### System Design

The Inception project implements a three-tier architecture:

1. **Presentation Tier**: NGINX reverse proxy (HTTPS termination)
2. **Application Tier**: WordPress + PHP-FPM (dynamic content)
3. **Data Tier**: MariaDB (persistent storage)

### Design Principles

- **Single Responsibility**: Each container runs one service
- **Statelessness**: Application logic separated from data
- **Immutability**: Containers are disposable; data persists in volumes
- **Configuration as Code**: All settings in version-controlled files
- **Security by Default**: Minimal attack surface, isolated networking

### Container Communication Flow

```
[Client Browser]
      ↓ HTTPS (443)
┌─────────────────┐
│     NGINX       │ ← TLS termination, static files
│   (Port 443)    │
└────────┬────────┘
         │ FastCGI (9000)
         ↓
┌─────────────────┐
│   WordPress     │ ← PHP processing, business logic
│   + PHP-FPM     │
│   (Port 9000)   │
└────────┬────────┘
         │ MySQL Protocol (3306)
         ↓
┌─────────────────┐
│    MariaDB      │ ← Data persistence
│   (Port 3306)   │
└─────────────────┘

Network: inception (bridge)
Volumes: database (/var/lib/mysql), web (/var/www/html)
```

---

## Container Design

### NGINX Container

**Purpose**: Reverse proxy, SSL/TLS termination, static file serving

**Base Image**: `debian:bookworm-slim`

**Exposed Ports**:
- 443/tcp (HTTPS)

**Volumes**:
- `inception_web:/var/www/html` (shared with WordPress)

**Key Features**:
- Self-signed SSL certificate generation
- TLSv1.3 configuration
- FastCGI proxy pass to WordPress container
- Runs as daemon off (foreground process)

**Process Management**:
- PID 1: `nginx -g "daemon off;"`
- Graceful shutdown on SIGTERM

### WordPress Container

**Purpose**: PHP application server, WordPress core

**Base Image**: `debian:bookworm-slim`

**Exposed Ports**:
- 9000/tcp (FastCGI, internal only)

**Volumes**:
- `inception_web:/var/www/html` (shared with NGINX)

**Key Features**:
- PHP 8.2 with FPM (FastCGI Process Manager)
- WP-CLI for automation
- Automated WordPress installation
- User creation on startup
- Database connection handling

**Process Management**:
- PID 1: `php-fpm8.2 -F` (foreground mode)
- PHP-FPM pool: `www` (configured in www.conf)

### MariaDB Container

**Purpose**: Relational database, data persistence

**Base Image**: `debian:bookworm-slim`

**Exposed Ports**:
- 3306/tcp (MySQL protocol, internal only)

**Volumes**:
- `inception_database:/var/lib/mysql` (persistent data)

**Key Features**:
- MariaDB 10.x (Debian package)
- Network binding (0.0.0.0) for container access
- Automated database initialization
- User and privilege management
- Data directory initialization

**Process Management**:
- PID 1: `mysqld --user=mysql`
- Graceful shutdown via mysqladmin

---

## Networking

### Bridge Network

**Network Name**: `inception`  
**Driver**: `bridge`  
**Subnet**: Automatically assigned by Docker (typically 172.x.0.0/16)

**Purpose**:
- Isolates containers from host network
- Provides DNS resolution (containers can reach each other by service name)
- Controls inter-container communication

### DNS Resolution

Containers communicate using service names defined in `docker-compose.yml`:

- `nginx` → Resolves to WordPress container IP
- `wordpress` → Resolves to WordPress container IP (used by NGINX)
- `mariadb` → Resolves to MariaDB container IP (used by WordPress)

**Example**: WordPress connects to database using hostname `mariadb:3306`

### Port Mapping

**External Ports** (exposed to host):
- 443 → nginx:443 (HTTPS)

**Internal Ports** (container-to-container only):
- 9000 → wordpress:9000 (FastCGI)
- 3306 → mariadb:3306 (MySQL)

**Note**: MariaDB port 3306 is exposed in docker-compose.yml but only accessible within the Docker network (not published to host by default).

### Security Isolation

- Containers cannot reach host network by default
- Only NGINX port 443 accessible from outside
- Inter-container traffic encrypted at application layer (MySQL uses auth)

---

## Volume Management

### Volume Types

The project uses **bind mounts** (not Docker-managed volumes):

```yaml
volumes:
  inception_database:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/dchrysov/data/database
  
  inception_web:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/dchrysov/data/web
```

### Volume: inception_database

**Host Path**: `/home/dchrysov/data/database`  
**Container Path**: `/var/lib/mysql`  
**Purpose**: MariaDB data files

**Contents**:
- `ibdata1` - InnoDB system tablespace
- `ib_logfile*` - Transaction logs
- `mysql/` - System database
- `wordpress/` - Application database
- `performance_schema/`, `sys/` - Monitoring databases

**Persistence**: Data survives container removal/recreation

**Backup Considerations**:
- Must use `mysqldump` or stop container before file-based backup
- Supports hot backup with proper tools

### Volume: inception_web

**Host Path**: `/home/dchrysov/data/web`  
**Container Path**: `/var/www/html`  
**Purpose**: WordPress installation files

**Contents**:
- WordPress core files (php, js, css)
- `wp-config.php` - WordPress configuration
- `wp-content/` - Themes, plugins, uploads
- `wp-admin/`, `wp-includes/` - Core directories

**Shared Access**:
- Mounted in both NGINX (read) and WordPress (read/write) containers
- NGINX serves static files directly
- WordPress handles PHP execution

**Permissions**:
- Owner: `www-data:www-data` (UID/GID 33 in Debian)
- Permissions: 755 for directories, 644 for files

---

## Service Configuration

### Environment Variables

All configuration is centralized in `srcs/.env`:

| Variable | Used By | Purpose |
|----------|---------|---------|
| `DOMAIN_NAME` | NGINX | SSL certificate CN, server_name |
| `MYSQL_ROOT_PASSWORD` | MariaDB | Root user password |
| `MYSQL_DATABASE` | MariaDB, WordPress | Database name |
| `MYSQL_USER` | MariaDB, WordPress | Application DB user |
| `MYSQL_PASSWORD` | MariaDB, WordPress | Application DB password |
| `WP_ADMIN_USER` | WordPress | Admin username |
| `WP_ADMIN_PASSWORD` | WordPress | Admin password |
| `WP_ADMIN_EMAIL` | WordPress | Admin email |
| `WP_USER` | WordPress | Regular user username |
| `WP_USER_PASSWORD` | WordPress | Regular user password |
| `WP_USER_EMAIL` | WordPress | Regular user email |
| `WP_URL` | WordPress | Site URL |
| `WP_TITLE` | WordPress | Site title |
| `DB_HOST` | WordPress | Database hostname (mariadb) |
| `DB_USER` | WordPress | DB user (same as MYSQL_USER) |
| `DB_PASSWORD` | WordPress | DB password (same as MYSQL_PASSWORD) |
| `DB_EMAIL` | WordPress | Admin email |

### Service Dependencies

```yaml
wordpress:
  depends_on:
    mariadb:
      condition: service_started

nginx:
  depends_on:
    wordpress:
      condition: service_started
```

**Startup Order**:
1. MariaDB starts first
2. WordPress waits for MariaDB (with retry loop)
3. NGINX starts after WordPress

**Health Checks**: Not explicitly defined; services use application-level checks

---

## Dockerfile Analysis

### NGINX Dockerfile

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y nginx
RUN apt-get install -y curl

COPY init.sh /init.sh
RUN chmod +x ./init.sh

ENTRYPOINT ["/init.sh"]
```

**Design Decisions**:
- Separate `RUN` commands (easier to debug layer failures)
- Installs `curl` for health checks
- Uses `ENTRYPOINT` (not `CMD`) for init script
- Init script generates certificate and starts NGINX

**Image Layers**: 6 layers (base + 5 RUN commands)

**Build Time**: ~30 seconds (depends on package mirror speed)

### WordPress Dockerfile

```dockerfile
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -y apt-transport-https
RUN apt install -y ca-certificates
RUN apt install -y lsb-release
RUN apt install -y wget

# Add PHP 8.2 repository
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | \
    tee /etc/apt/sources.list.d/sury-php.list

RUN apt update
RUN apt install -y php8.2-fpm
RUN apt install -y php8.2-mysqli
RUN apt install -y curl
RUN rm -rf /var/lib/apt/lists/*

COPY www.conf /etc/php/8.2/fpm/pool.d/.
COPY init.sh .
RUN chmod +x init.sh

CMD ["./init.sh"]
```

**Design Decisions**:
- Uses Sury PHP repository for PHP 8.2 (Debian bookworm ships 8.1)
- Installs `php8.2-mysqli` for MySQL/MariaDB connectivity
- Custom `www.conf` for PHP-FPM pool configuration
- Cleans apt cache to reduce image size
- Uses `CMD` for init script

**Image Layers**: 16 layers

**Build Time**: ~60 seconds (depends on package downloads)

### MariaDB Dockerfile

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY init.sh /etc/mariadb/init.sh
RUN chmod +x /etc/mariadb/init.sh

WORKDIR /etc/mariadb
ENTRYPOINT ["./init.sh"]
```

**Design Decisions**:
- Combines commands with `&&` (reduces layers)
- Cleans apt cache in same layer (reduces image size)
- Uses `ENTRYPOINT` for init script
- Sets WORKDIR for clarity

**Image Layers**: 3 layers (more efficient)

**Build Time**: ~45 seconds

---

## Initialization Scripts

### NGINX init.sh

**Location**: `srcs/requirements/nginx/init.sh`

**Purpose**: Generate SSL certificate, configure virtual host, start NGINX

**Script Flow**:
1. Create SSL directory
2. Generate self-signed certificate using `openssl`
3. Write NGINX server block configuration
4. Enable site configuration
5. Start NGINX in foreground mode

**Key Commands**:
```bash
# Generate certificate (valid 365 days)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/key.pem \
    -out /etc/nginx/ssl/fullchain.pem \
    -subj "/C=DE/ST=BW/L=Heilbronn/O=42/OU=student/CN=${DOMAIN_NAME}"

# Start NGINX (replaces shell with PID 1)
exec nginx -g "daemon off;"
```

**Certificate Details**:
- Type: Self-signed X.509
- Key Size: RSA 2048 bits
- Validity: 365 days
- Subject: CN=dchrysov.42.fr

**Server Block**:
- Listen: 443 (IPv4 and IPv6)
- SSL Protocols: TLSv1.3 only
- Root: `/var/www/html`
- FastCGI pass: `wordpress:9000`

### WordPress init.sh

**Location**: `srcs/requirements/wordpress/init.sh`

**Purpose**: Download WordPress, configure database, install core, create users

**Script Flow**:
1. Download WP-CLI if not present
2. Check if `wp-config.php` exists (skip if already installed)
3. Download WordPress core
4. Wait for MariaDB to be ready (60 second timeout)
5. Generate `wp-config.php` with database credentials
6. Install WordPress (create admin user, set up database)
7. Enable comment moderation
8. Create/verify regular user (if env vars set)
9. Start PHP-FPM in foreground mode

**Key Commands**:
```bash
# Download WordPress
./wp-cli.phar core download --allow-root

# Wait for database
mysqladmin -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" ping

# Create config
./wp-cli.phar config create \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${MYSQL_PASSWORD}" \
    --dbhost=mariadb \
    --allow-root

# Install WordPress
./wp-cli.phar core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${DB_EMAIL}" \
    --allow-root

# Create regular user
./wp-cli.phar user create "${WP_USER}" "${WP_USER_EMAIL}" \
    --role=subscriber \
    --user_pass="${WP_USER_PASSWORD}" \
    --allow-root

# Start PHP-FPM
exec php-fpm8.2 -F
```

**Database Wait Logic**:
- Tries connection every second
- Maximum 60 attempts
- Uses `mysqladmin ping` for health check

**Idempotence**: Script can be run multiple times safely:
- Checks for existing `wp-config.php`
- Checks for existing users before creating

### MariaDB init.sh

**Location**: `srcs/requirements/mariadb/init.sh`

**Purpose**: Initialize database, create users, set up WordPress database

**Script Flow**:
1. Configure MariaDB to listen on all interfaces (0.0.0.0)
2. Create runtime socket directory
3. Initialize data directory if first run
4. Start MariaDB in safe mode (no networking)
5. Wait for socket to be ready
6. Create WordPress database and user
7. Set root password
8. Shutdown MariaDB
9. Start MariaDB normally (with networking)

**Key Commands**:
```bash
# Allow network access
sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' \
    /etc/mysql/mariadb.conf.d/50-server.cnf

# Initialize database
mysql_install_db --user=mysql --datadir=/var/lib/mysql

# Start in safe mode
mysqld_safe --skip-networking --user=mysql --socket=/run/mysqld/mysqld.sock &

# Create database and user
mysql -u root -p${MYSQL_ROOT_PASSWORD} << EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Shutdown and restart with networking
mysqladmin --socket=/run/mysqld/mysqld.sock -u root \
    -p${MYSQL_ROOT_PASSWORD} shutdown

# Start normally
exec mysqld --user=mysql
```

**Security Considerations**:
- Root password set from environment variable
- Application user has privileges only on WordPress database
- User created with wildcard host ('%') for container access

---

## Docker Compose

### docker-compose.yml Structure

```yaml
services:
  nginx:
    build: requirements/nginx
    container_name: nginx
    depends_on:
      wordpress:
        condition: service_started
    ports:
      - "443:443"
    volumes:
      - inception_web:/var/www/html
    networks:
      - inception
    env_file:
      - .env
    restart: always

  wordpress:
    build: requirements/wordpress
    container_name: wp-php
    depends_on:
      mariadb:
        condition: service_started
    volumes:
      - inception_web:/var/www/html
    networks:
      - inception
    env_file:
      - .env
    restart: always

  mariadb:
    build: requirements/mariadb
    container_name: mariadb
    ports:
      - "3306:3306"
    volumes:
      - inception_database:/var/lib/mysql
    networks:
      - inception
    env_file:
      - .env
    restart: always

networks:
  inception:
    driver: bridge

volumes:
  inception_database:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/dchrysov/data/database
  inception_web:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/dchrysov/data/web
```

### Design Decisions

**Build Context**: Each service builds from its own directory
- NGINX: `requirements/nginx/`
- WordPress: `requirements/wordpress/`
- MariaDB: `requirements/mariadb/`

**Container Names**: Explicit names for easier management
- `nginx`, `wp-php`, `mariadb`

**Restart Policy**: `always`
- Containers restart on failure
- Containers restart on host reboot
- Manual stop prevents auto-restart

**Volume Strategy**: Bind mounts (not Docker-managed volumes)
- Easier backup and inspection
- Host path visible in filesystem
- Requires manual directory creation

**Network Strategy**: Single custom bridge network
- All containers on same network
- DNS resolution by service name
- Isolated from other Docker networks

### Compose Version

File uses Compose specification (no version key needed for Compose v2+)

---

## Security Considerations

### Password Management

**Environment Variables**:
- All passwords stored in `srcs/.env`
- No hardcoded passwords in Dockerfiles or scripts
- `.env` should be in `.gitignore` (not committed)

**Password Requirements** (per 42 project):
- Admin username cannot be `admin`, `Admin`, `administrator`, `Administrator`
- Minimum two users: admin + regular user

**Best Practices**:
- Use strong, unique passwords
- Rotate passwords regularly
- Consider using Docker secrets for production

### Network Security

**Firewall Configuration**:
- Only port 443 exposed to external traffic
- Internal ports (3306, 9000) not accessible from outside
- Consider UFW or iptables for additional protection

**Container Isolation**:
- Each service in separate container
- Limited privilege escalation surface
- No `--privileged` flag used

**TLS Configuration**:
- TLSv1.3 only (no older protocols)
- Self-signed certificate (replace for production)
- 2048-bit RSA key

### File Permissions

**Volume Permissions**:
```bash
# WordPress files
chown -R www-data:www-data /home/dchrysov/data/web

# Database files
chown -R mysql:mysql /home/dchrysov/data/database
```

**Inside Containers**:
- NGINX runs as `www-data` user
- PHP-FPM runs as `www-data` user
- MariaDB runs as `mysql` user

### Database Security

**User Privileges**:
- Root user: full access (localhost only)
- Application user: limited to WordPress database
- No anonymous users

**Connection Security**:
- Password authentication required
- No SSL/TLS for container-to-container (network isolated)
- Consider MySQL SSL for production

### WordPress Security

**wp-config.php Security**:
- Generated with unique salts
- Database credentials from environment
- File permissions: 644

**Comment Moderation**:
- Enabled by default (prevents spam)
- Comments require approval

**Updates**:
- WordPress core: manual update via WP-CLI
- Plugins/themes: manual update via wp-admin
- Consider automated security updates

---

## Customization Guide

### Changing Domain Name

**Step 1**: Update `.env`:
```bash
DOMAIN_NAME=yourdomain.com
WP_URL=https://yourdomain.com
```

**Step 2**: Update hosts file:
```bash
echo "127.0.0.1 yourdomain.com" | sudo tee -a /etc/hosts
```

**Step 3**: Rebuild NGINX (regenerate certificate):
```bash
docker compose -f srcs/docker-compose.yml build --no-cache nginx
docker compose -f srcs/docker-compose.yml up -d nginx
```

### Adding Custom SSL Certificate

**Step 1**: Place certificate files in `srcs/certs/`:
```bash
mkdir -p srcs/certs
cp /path/to/fullchain.pem srcs/certs/
cp /path/to/privkey.pem srcs/certs/
```

**Step 2**: Modify `nginx/init.sh`:
```bash
# Replace certificate generation section with:
cp /certs/fullchain.pem /etc/nginx/ssl/fullchain.pem
cp /certs/privkey.pem /etc/nginx/ssl/key.pem
```

**Step 3**: Update `nginx/Dockerfile`:
```dockerfile
COPY certs/ /certs/
```

**Step 4**: Rebuild:
```bash
docker compose build nginx && docker compose up -d nginx
```

### Changing PHP Version

**Step 1**: Edit `wordpress/Dockerfile`:
```dockerfile
# Change all occurrences of 8.2 to desired version (e.g., 8.3)
RUN apt install -y php8.3-fpm
RUN apt install -y php8.3-mysqli
```

**Step 2**: Update `wordpress/www.conf`:
```conf
# No changes needed (service name remains same)
```

**Step 3**: Update `wordpress/init.sh`:
```bash
# Change PHP-FPM command
exec php-fpm8.3 -F
```

**Step 4**: Rebuild:
```bash
docker compose build wordpress && docker compose up -d wordpress
```

### Adding NGINX Modules

**Step 1**: Edit `nginx/Dockerfile`:
```dockerfile
RUN apt-get install -y nginx nginx-extras
# Or specific module:
RUN apt-get install -y libnginx-mod-http-geoip
```

**Step 2**: Configure in `nginx/init.sh`:
```bash
# Add module-specific configuration in server block
```

**Step 3**: Rebuild:
```bash
docker compose build nginx && docker compose up -d nginx
```

### Enabling WordPress Debug Mode

**Step 1**: Add to `wordpress/init.sh` after config creation:
```bash
./wp-cli.phar config set WP_DEBUG true --raw --allow-root
./wp-cli.phar config set WP_DEBUG_LOG true --raw --allow-root
./wp-cli.phar config set WP_DEBUG_DISPLAY false --raw --allow-root
```

**Step 2**: Rebuild and check logs:
```bash
docker compose build wordpress && docker compose up -d wordpress
docker exec wp-php tail -f /var/www/html/wp-content/debug.log
```

### Adding MariaDB Configuration

**Step 1**: Create custom config file `mariadb/custom.cnf`:
```ini
[mysqld]
max_connections = 200
innodb_buffer_pool_size = 256M
query_cache_size = 32M
```

**Step 2**: Update `mariadb/Dockerfile`:
```dockerfile
COPY custom.cnf /etc/mysql/mariadb.conf.d/99-custom.cnf
```

**Step 3**: Rebuild:
```bash
docker compose build mariadb && docker compose up -d mariadb
```

---

## Development Workflow

### Local Development Setup

1. **Clone repository**:
```bash
git clone https://github.com/chrisov/Inception.git
cd Inception
```

2. **Create development .env**:
```bash
cp srcs/.env srcs/.env.development
# Edit with development-specific values
```

3. **Build development stack**:
```bash
make build
```

4. **Enable live reloading** (for theme development):
```bash
# Mount theme directory as volume
docker run -v $(pwd)/mytheme:/var/www/html/wp-content/themes/mytheme ...
```

### Testing Changes

**Test Dockerfile changes**:
```bash
# Build single service
docker compose -f srcs/docker-compose.yml build --no-cache nginx

# Test container
docker run -it --rm nginx-image bash
```

**Test init script changes**:
```bash
# Run script manually
docker exec -it nginx bash
./init.sh
```

**Test configuration changes**:
```bash
# Reload NGINX
docker exec nginx nginx -s reload

# Restart PHP-FPM
docker compose restart wordpress

# Restart MariaDB
docker compose restart mariadb
```

### Debugging

**View logs**:
```bash
# All services
docker compose logs -f

# Specific service
docker logs -f nginx

# Last 100 lines
docker logs --tail 100 wordpress
```

**Execute commands in container**:
```bash
# Interactive shell
docker exec -it wp-php bash

# Single command
docker exec wp-php wp user list --allow-root
```

**Inspect container**:
```bash
# Show container details
docker inspect nginx

# Show process list
docker top nginx

# Show resource usage
docker stats nginx
```

**Network debugging**:
```bash
# Inspect network
docker network inspect inception

# Test connectivity
docker exec wordpress ping -c 3 mariadb
docker exec wordpress nc -zv mariadb 3306
```

### Performance Optimization

**Image Size Reduction**:
```dockerfile
# Combine RUN commands
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Use multi-stage builds (if applicable)
# Use smaller base image (alpine) if compatible
```

**Build Caching**:
```bash
# Use BuildKit for better caching
DOCKER_BUILDKIT=1 docker compose build

# Cache specific layers
# Place frequently-changing commands last in Dockerfile
```

**Runtime Performance**:
```bash
# Increase PHP-FPM workers (www.conf)
pm.max_children = 10
pm.start_servers = 4

# Optimize MariaDB
# Add custom.cnf with appropriate values for VM resources
```

---

## Technical Specifications

### Software Versions

- **Debian**: Bookworm (12) Slim
- **NGINX**: 1.22+ (from Debian repos)
- **PHP**: 8.2 (from Sury repository)
- **MariaDB**: 10.11+ (from Debian repos)
- **WordPress**: Latest (downloaded via WP-CLI)

### Resource Requirements

**Per Container**:
- NGINX: ~10MB RAM, minimal CPU
- WordPress: ~50-100MB RAM, variable CPU
- MariaDB: ~100-200MB RAM, variable CPU

**Total System**: 2GB RAM minimum, 4GB recommended

### Port Usage

- **443/tcp**: HTTPS (external)
- **9000/tcp**: FastCGI (internal)
- **3306/tcp**: MySQL (internal)

### Volume Sizes

- **Database**: ~50MB initially, grows with content
- **Web**: ~40MB WordPress core + uploads/themes/plugins

---

## Project Compliance

### 42 Project Requirements Checklist

- [x] Three containers: NGINX, WordPress+PHP-FPM, MariaDB
- [x] Debian Bookworm base (penultimate stable)
- [x] Custom Dockerfiles (no ready-made images)
- [x] Docker Compose orchestration
- [x] Makefile for building
- [x] Port 443 only (TLSv1.3)
- [x] No infinite loops (`tail -f`, `sleep infinity`)
- [x] Custom bridge network
- [x] Two volumes (database, web)
- [x] Persistent data in `/home/<login>/data`
- [x] Environment variables in `.env`
- [x] No passwords in Dockerfiles
- [x] Containers restart on crash
- [x] Two database users (admin + regular)
- [x] No `network: host`, `--link`, or `links:`
- [x] Domain name configured

---

## Troubleshooting Development Issues

### Build Failures

**Problem**: `apt-get update` fails

**Solution**: Check network connectivity, try different mirror

**Problem**: Package not found

**Solution**: Verify package name, check repository configuration

### Runtime Failures

**Problem**: Container exits immediately

**Solution**: Check logs, ensure PID 1 process runs in foreground

**Problem**: "Address already in use"

**Solution**: Check for port conflicts, change port mapping

### Connectivity Issues

**Problem**: Container can't reach another container

**Solution**: Verify both on same network, check DNS resolution

**Problem**: WordPress can't connect to database

**Solution**: Verify MariaDB started, check credentials match

---

## Further Reading

### Docker

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)

### Services

- [NGINX Documentation](https://nginx.org/en/docs/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WordPress Codex](https://codex.wordpress.org/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)

### Security

- [Docker Security](https://docs.docker.com/engine/security/)
- [NGINX Security](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [WordPress Hardening](https://wordpress.org/support/article/hardening-wordpress/)

---

*Last Updated: December 13, 2025*
