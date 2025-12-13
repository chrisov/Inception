# Inception

> A Docker-based infrastructure project implementing a secure WordPress hosting environment with NGINX, MariaDB, and PHP-FPM.

[![42 Project](https://img.shields.io/badge/42-Project-blue)](https://42.fr)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Author:** dchrysov  
**School:** 42  
**Project:** Inception

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Services](#services)
- [Configuration](#configuration)
- [Usage](#usage)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [License](#license)

---

## 🎯 Overview

**Inception** is a system administration and DevOps project from the 42 curriculum that focuses on containerization and infrastructure orchestration. The goal is to set up a small but production-ready infrastructure using Docker, composed of multiple services working together to host a WordPress website.

This project demonstrates:
- Containerization best practices with custom Docker images
- Service orchestration using Docker Compose
- Secure networking and data persistence
- SSL/TLS implementation for HTTPS
- Infrastructure as Code (IaC) principles

### Key Objectives

- Build custom Docker images from scratch (Debian/Alpine base only)
- Configure a multi-container application with proper networking
- Implement secure HTTPS-only access via NGINX reverse proxy
- Ensure data persistence through Docker volumes
- Follow security best practices (no hardcoded passwords, proper isolation)

---

## ✨ Features

- **🔒 HTTPS Only**: Secure communication via TLSv1.3 on port 443
- **🐳 Custom Containers**: All images built from scratch, no pre-built images from Docker Hub
- **🔄 Auto-restart**: Containers automatically restart on failure
- **💾 Persistent Data**: Database and web files stored in dedicated volumes
- **🌐 Custom Domain**: Configured for `dchrysov.42.fr` with local hosts file
- **👥 Multi-user Support**: Separate admin and regular WordPress users
- **🚀 One-command Deploy**: Simple Makefile for building and running the stack

---

## 🏗️ Architecture

The infrastructure consists of three main services running in isolated Docker containers:

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Host (VM)                     │
│                                                         │
│  ┌────────────┐        ┌─────────────┐                  │
│  │   NGINX    │───────▶│  WordPress  │                  │
│  │  (Port 443)│        │  + PHP-FPM  │                  │
│  │  Reverse   │        │             │                  │
│  │   Proxy    │        │  (Port 9000)│                  │
│  └────────────┘        └──────┬──────┘                  │
│       ▲                       │                         │
│       │                       │                         │
│   HTTPS (TLS)                 │                         │
│       │                       ▼                         │
│       │                ┌─────────────┐                  │
│   [Client]             │   MariaDB   │                  │
│                        │  (Port 3306)│                  │
│                        │  Database   │                  │
│                        └─────────────┘                  │
│                                                         │
│  Volumes: /home/dchrysov/data/                          │
│    ├── database/  (MariaDB data)                        │
│    └── web/       (WordPress files)                     │
└─────────────────────────────────────────────────────────┘
```

**Network**: All containers communicate via a custom bridge network named `inception`.

---

## 📦 Prerequisites

### System Requirements

- **Virtual Machine** running Ubuntu/Debian Linux
- **Minimum**: 2GB RAM, 2 CPU cores, 10GB disk space
- **Recommended**: 4GB RAM, 4 CPU cores, 20GB disk space

### Software Requirements

- Docker Engine (v20.10+)
- Docker Compose (v2.0+)
- GNU Make
- Root or sudo access

### Network Requirements

- Ability to bind to port 443 (HTTPS)
- Domain name configured in `/etc/hosts` (see [SETUP.md](SETUP.md))

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/chrisov/Inception.git
cd Inception
```

### 2. Configure Environment

Edit `srcs/.env` with your desired configuration:

```bash
nano srcs/.env
```

**Important**: Change default passwords before deploying!

### 3. Add Domain to Hosts File

```bash
echo "127.0.0.1 dchrysov.42.fr" | sudo tee -a /etc/hosts
```

### 4. Build and Start Services

```bash
make build
```

This command will:
- Create required data directories
- Build all Docker images from scratch
- Start all containers in detached mode

### 5. Verify Installation

Check that all services are running:

```bash
make status
```

### 6. Access WordPress

Open your browser and navigate to:
```
https://dchrysov.42.fr
```

**Note**: You'll see a browser warning about the self-signed certificate. This is expected. Accept the certificate to continue.

### Default Credentials

**Admin User:**
- Username: `dimi`
- Password: `dimi` (⚠️ Change this!)

**Database User:**
- Username: `wpuser`
- Password: `wppass` (⚠️ Change this!)

For detailed installation instructions, see [SETUP.md](SETUP.md).

---

## 📁 Project Structure

```
Inception/
├── Makefile                      # Build and orchestration commands
├── README.md                     # This file
├── LICENSE                       # MIT License
├── SETUP.md                      # Detailed setup instructions
├── srcs/
│   ├── docker-compose.yml        # Service orchestration
│   ├── .env                      # Environment variables
│   ├── requirements/
│   │   ├── nginx/
│   │   │   ├── Dockerfile        # NGINX container definition
│   │   │   └── init.sh           # NGINX entrypoint script
│   │   ├── wordpress/
│   │   │   ├── Dockerfile        # WordPress + PHP-FPM container
│   │   │   ├── init.sh           # WordPress setup script
│   │   │   └── www.conf          # PHP-FPM pool configuration
│   │   └── mariadb/
│   │       ├── Dockerfile        # MariaDB container definition
│   │       └── init.sh           # Database initialization script
│   └── certs/                    # SSL certificates (generated)
├── logs/                         # Service logs (generated)
└── /home/dchrysov/data/          # Persistent data (on host)
    ├── database/                 # MariaDB data files
    └── web/                      # WordPress installation
```

---

## 🔧 Services

### NGINX (Reverse Proxy)

- **Image**: Custom built from Debian Bookworm
- **Port**: 443 (HTTPS only)
- **Function**: 
  - SSL/TLS termination
  - Reverse proxy to PHP-FPM
  - Static file serving
  - Security headers

**Key Features:**
- Self-signed SSL certificate generation
- TLSv1.3 support
- FastCGI proxy to WordPress container

### WordPress + PHP-FPM

- **Image**: Custom built from Debian Bookworm with PHP 8.2
- **Port**: 9000 (internal, FastCGI)
- **Function**:
  - WordPress core installation
  - PHP-FPM process manager
  - WP-CLI for automation

**Key Features:**
- Automated WordPress installation
- User creation and management
- Comment moderation enabled
- Database connection handling

### MariaDB (Database)

- **Image**: Custom built from Debian Bookworm
- **Port**: 3306 (internal)
- **Function**:
  - MySQL-compatible database
  - WordPress data storage
  - User and privilege management

**Key Features:**
- Automated database initialization
- Secure password handling
- Network-accessible configuration
- Data persistence

---

## ⚙️ Configuration

### Environment Variables

All configuration is managed through `srcs/.env`:

| Variable | Description | Example |
|----------|-------------|---------|
| `DOMAIN_NAME` | Your domain name | `dchrysov.42.fr` |
| `MYSQL_ROOT_PASSWORD` | MariaDB root password | `secure_root_pass` |
| `MYSQL_DATABASE` | WordPress database name | `wordpress` |
| `MYSQL_USER` | Database user | `wpuser` |
| `MYSQL_PASSWORD` | Database user password | `secure_db_pass` |
| `WP_ADMIN_USER` | WordPress admin username | `admin` |
| `WP_ADMIN_PASSWORD` | WordPress admin password | `secure_admin_pass` |
| `WP_ADMIN_EMAIL` | Admin email address | `admin@example.com` |
| `WP_URL` | Site URL | `https://dchrysov.42.fr` |
| `WP_TITLE` | Site title | `My WordPress Site` |

### Docker Compose

The `docker-compose.yml` defines:
- Service dependencies
- Network configuration
- Volume mounts
- Build contexts
- Restart policies

### Volumes

Two persistent volumes are configured:

1. **inception_database**: MariaDB data
   - Host path: `/home/dchrysov/data/database`
   - Container path: `/var/lib/mysql`

2. **inception_web**: WordPress files
   - Host path: `/home/dchrysov/data/web`
   - Container path: `/var/www/html`

---

## 🎮 Usage

### Makefile Commands

The project includes a comprehensive Makefile for easy management:

```bash
# Build and start all services
make build

# Start services (without rebuild)
make up

# Stop all services
make down

# Restart services
make restart

# View logs in files
make logs

# Check container status
make status

# Clean containers and volumes (keep images)
make clean

# Complete cleanup (including data)
make fclean

# Show available commands
make help
```

### Direct Docker Compose Commands

You can also use Docker Compose directly:

```bash
# View logs in real-time
docker compose -f srcs/docker-compose.yml logs -f

# View logs for specific service
docker compose -f srcs/docker-compose.yml logs nginx

# Execute command in container
docker compose -f srcs/docker-compose.yml exec wordpress bash

# Rebuild specific service
docker compose -f srcs/docker-compose.yml up -d --build nginx
```

### Accessing Services

- **WordPress Site**: https://dchrysov.42.fr
- **WordPress Admin**: https://dchrysov.42.fr/wp-admin
- **Database**: Accessible only within Docker network

---

## 📚 Documentation

This project includes comprehensive documentation:

 - **[USER_DOC.md](USER_DOC.md)**: End-user guide for installing, configuring, and operating the stack
   - Prerequisites and environment setup
   - Domain and hosts file configuration
   - Building, starting, stopping services (Makefile and Compose)
   - WordPress access and administration (users, themes, plugins)
   - Troubleshooting, backup and restore procedures

 - **[DEV_DOC.md](DEV_DOC.md)**: Developer-focused technical documentation
   - Container architecture and design decisions
   - Networking and volume management specifics for this implementation
   - Dockerfile breakdowns and init script flows (NGINX/WordPress/MariaDB)
   - Security considerations and customization guides (SSL, PHP versions, configs)
   - Development workflow, debugging, and performance optimization tips

---

## 🔍 Troubleshooting

### Quick Diagnostics

```bash
# Check if all containers are running
docker ps

# View container logs
make logs

# Check service status
make status

# Verify network connectivity
docker network inspect inception

# Check volumes
docker volume ls
```

### Common Issues

**Port 443 Permission Denied**
- Solution: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for rootless Docker setup

**Browser Certificate Warning**
- Expected behavior with self-signed certificates
- Accept the certificate to continue

**Cannot Connect to Database**
- Check that MariaDB container is healthy
- Verify environment variables in `.env`

For detailed solutions, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## 🔐 Security Considerations

### Important Security Notes

⚠️ **Default Passwords**: Change ALL default passwords in `srcs/.env` before deployment

⚠️ **Self-Signed Certificates**: For production, use proper CA-signed certificates

⚠️ **Exposed Ports**: Only port 443 should be accessible externally

⚠️ **Secrets Management**: Never commit passwords to version control

### Recommended Actions

1. Use strong, unique passwords for all services
2. Regularly update base images and dependencies
3. Implement backup strategy for volumes
4. Monitor container logs for suspicious activity
5. Use Docker secrets for production deployments

For comprehensive security guidelines, see [SECURITY.md](SECURITY.md).

---

## 🧪 Testing

### Verify Installation

```bash
# Test HTTPS endpoint
curl -k https://dchrysov.42.fr

# Test database connectivity
docker compose exec wordpress wp db check --allow-root

# Check SSL certificate
openssl s_client -connect dchrysov.42.fr:443 -servername dchrysov.42.fr

# Verify WordPress installation
docker compose exec wordpress wp core version --allow-root
```

---

## 📖 Learning Resources

### Docker & Containerization

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Best Practices for Dockerfiles](https://docs.docker.com/develop/dev-best-practices/)

### Web Services

- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI Documentation](https://wp-cli.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php)

### Security

- [SSL/TLS Best Practices](https://wiki.mozilla.org/Security/Server_Side_TLS)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

---

## 🤝 Contributing

This is an educational project from the 42 curriculum. While contributions are not expected, feedback and suggestions are welcome.

### AI Usage Disclosure

As per 42 guidelines, AI tools were used in this project for:
- Technical explanations and concept clarification
- Reducing repetitive configuration tasks
- Code review and debugging assistance

All AI-generated content was thoroughly understood, reviewed, tested, and peer-reviewed before inclusion.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**dchrysov**
- 42 Student
- Project: Inception
- Year: 2025

---

## 🙏 Acknowledgments

- 42 Network for the comprehensive curriculum
- Docker community for excellent documentation
- Open source communities of NGINX, WordPress, and MariaDB

---

**Project Status**: ✅ Completed

*Last Updated: December 13, 2025*
