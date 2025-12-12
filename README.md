<a name="top"></a>

<div align="center">
  <img src="https://www.dieter-schwarz-stiftung.de/files/Projects/Project%20logos/Logo_42HN-min.jpg" alt="Logo"/>
</div>

<br>
<div align="center">

### 🛠 Docker (Compose)

</div>



# Inception

## 1. Overview

The project creates of a LEMP stack setup, using *Linux* as the host operating system, *Nginx* as the web server to handle HTTP requests, *MariaDB* as the relational database management system and *PHP* as the server side programming language to process requests and generate dynamic content. 

It offers *performance*, as Nginx can handle mulitple concurrent requests, with low memory usage and *flexibility* as it is able to work well with for modern high-traffic websites. 

The project's main components of the setup are explained in the following sections.

<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## 2. Docker Compose

## 3. Nginx

Nginx is an open source web server and reverse proxy service. 

- It can work as the traffic controller for web requests: deciding what happens when a user’s browser asks for something (like a web page or image).

- It can serve the files directly: when the user is visiting `https://example.com`, Nginx looks for the corresponding .html file and returns it.

- It can also work as *reverse proxy*: forwards requests to another service, such as a backend app.

- It can also handle encryption (TLS/SSL certificates), so that apps don't need to.


### 3.1 Installation / run

<div align="center">

| Command                          | Description                   |
|----------------------------------|-------------------------------|
| `$ sudo apt install nginx`       | Downloads and installs Nginx |

Table T3.1.1: Nginx intallation command

</div>
<br>

<div align="center">

| Ports               | Logs                                    |
|---------------------|-----------------------------------------|
| 80 (Default HTTP)   | /var/log/nginx/access.log (Access logs) |
| 443 (Default HTTPS) | /var/log/nginx/error.log (Error logs)   |

  Table 2.1.2: Configuration details, useful for debugging.
</div>
<br>


### 3.2 Dockerfile

The Dockerfile for Nginx:

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/05c9ca967a11cf28b231eb06a3621e936c5bd8cc/srcs/requirements/nginx/dfile.png" width="400" alt="nginx dockerfile"/>
  <br>
  Figure F3.2.1: Nginx Dockerfile
</div>
<br>


We have already copied and modified the configuration file `/etc/nginx/sites-available/default`, from inside the container outside, in order to set up the communication with the PHP, by opening up port 9000. After that, we have to replace the original configuration file, with the modified one.

**IMPORTANT**: The Nginx's `-g "daemon off;"` flag sets a global configuration directive from the command line, instead of only from the configuration file (nginx.conf), as it disables Nginx's defaut behavior of running in the background, as a deamon. Instead, with this directive, the process remains in the foreground, so the container's process can stay alive and running.


### 3.3 Single Container

Running the single container is useful when first setting up the service, to check if there is any misconfiguration in the Dockerfile. In the case of the Nginx service, we don't want to copy any configuration file back into the container, as this will override any default global instructions and make the container listen for the wp-php's container's port 9000.

If we uncomment that part (*line 8*), the container can stay alive and running and we can then check for the specific port in the localhost for Nginx's welcome message. Otherwise the container's creation will **fail**. To test it, we build and run the container:

```
$ docker build -t nginx {path_to_dockerfile}
$ docker run -d -p 8080:80 nginx
```

This Dockerfile starts the web server and is listening for requests. We can already access it in the local port 80 `https://localhost/8080`. If the engine started correctly, we will be able to see a Nginx welcome message!



<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## 4. Wordpress / PHP

Wordpress is an open source Content Management System (CMS), which basically means that it lets the user build websites and blogs, without coding everything from scratch. It is written in PHP and uses a MySQL/MariaDB database. When a request requires PHP execution (like loading a WordPress page), Nginx passes the request to PHP-FPM (FastCGI Process Manager), then returns the result back to the Nginx, and finally Nginx sends it back to the client.


### 4.1 Installation / run

<div align="center">
  
| Command                             | Description                    |
|-------------------------------------|--------------------------------|
| `$ apt install php8.2-fpm`          | Downloads and installs PHP-FPM |
| `$ apt install php8.2-mysql`        | Downloads and installs PHP-FPM |
| `$ apt install apt-transport-https` | Enable HTTPS Support.          |
| `$ apt install ca-certificates`     | Trust Secure Connections.      |
| `$ apt install lsb-release`         | Identify the OS.               |
| `$ apt install wget`                | Download Tool.                 |
| `$ wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg` | Download and Trust the Key |
| `$ echo "..."`                      | Add the Repository URL         |

  Table T4.1.1: Wordpress Dockerfile dependencies.
</div>
<br>


### 4.2 Dockerfile

The Dockerfile for WP-PHP:

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/37d4d53ec64d2ed7c2a0bfa2b9c6751c59f177f6/srcs/requirements/wordpress/dfile.png" width="700" alt="nginx dockerfile"/>
  <br>
  Figure F4.2.1: Worpress Dockerfile
</div>
  <br>


Without proper configuration, the two services (Ngnix, PHP) cannot communicate. To achieve that, we need to access the PHP-FPM's pool configuration file, `/etc/php/8.2/fpm/pool.d/www.conf` and set up the communicaton channel in port 9000.

This Dockerfile starts the container on a PHP image, copies the configuration file from the project's directory into the container, since that file is already properly modified and it will allow the communication with Nginx to happen. 

**IMPORTANT**: The PHP's `-F` flag, is used, similarly to Ngnix, to bring the running process on the foreground, so that the container can remain alive and running. Without it, the container would start the process and then exit.


### 4.3 Double Containers

As was the case for Nginx, to run a single wp-php container, in combination with the Nginx service of course, we need to configure the default global configurations, to make it listen for the appropriate port.

Create a custom test network for both of the container to communicate through:

```$ docker network create {network_name}```

Modify the www.conf file to listen to any IP in the network `listen = 0.0.0.0:9000` (the network is only gonna include the two containers). Modify the command to call the executable in the foreground `CMD ["/usr/sbin/php-fpm8.2", "-F"]`, then build the container, commenting out the lines that correspond to the running script (line 23, 24):

```$ docker build -t wp-php-simple {path_to_dockerfile}```

Run the container with a few parameters:

```$ docker run -d --network {network_name} --volume "$(pwd)/../web/":/var/www/html/ wp-php-simple```

Extract the IP Address of the running container:

```$ docker inspect -f {cont_name} | grep "IP"```

Modify the nginx default configuration file to use that same IP address `fastcgi_pass {IP_Address}:9000` as the wp-php container.
Build and run the Nginx container with the appropriate parameters:

```
$ docker build -t nginx {path_to_dockerfile}
$ docker run -d --network {network_name} --volume "$(pwd)/../web/":/var/www/html/ -p 8080:80 nginx
```

Both of the containers should be up and running. We put any simple test .html or .php file in the web subdirectory (the shared one) and if access the specified localhost port we should be able to render it.

<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## 5. MariaDB

MariaDB is an open source database management system, similar to MySQL in terms of commands and protocols, that the user can use to store, organize, and query structured data in the format of tables, with rows and columns. 

- It can connect data between tables using *primary* (unique IDs) and *foreign* keys (references).

- The user can insert, update delete and fetch data, using *SQL*.

- It can control which user can have access to which database.


### 5.1 Installation / run

| Command                               | Description                               |
|---------------------------------------|-------------------------------------------|
| `$ sudo apt install mariadb-server`   | Sets up the database engine in the system |
| `$ sudo mysql -u root -p`             | Access MariaDB as root user               |
| `$ sudo systemctl start mariadb`      | Start MariaDB engine                      |
| `$ sudo systemctl enable mariadb`     | Enables MariaDB service on boot           |
| `$ sudo systemctl status mariadb`     | Checks MariaDB service's status           |
| `$ sudo systemctl restart mariadb`    | Restarts after config changes             |
| `$ sudo systemctl stop mariadb`       | Stops MariaDB engine                      |
| `$ sudo mysql_secure_installation`    |                                           |


### 5.2 Dockerfile



### 5.3 Technical details

| SQL Commands | Constraints | Configuration                           |
|--------------|-------------|-----------------------------------------|
| CREATE	     | PRIMARY KEY | /etc/mysql/mariadb.conf.d/50-server.cnf |
| INSERT       | FOREIGN KEY | 3306 (Default Port)                     |
| DELETE
| SELECT
| UPDATE


<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>



VM

1. create the droplet (ubuntu desktop)

2. ssh root@<DROPLET_PUBLIC_IP>

sudo apt update && sudo apt upgrade -y
sudo apt update
sudo apt install xubuntu-desktop -y
sudo apt install xfce4 xfce4-goodies tigervnc-standalone-server x11-xserver-utils xterm dbus-x11 -y
sudo apt install xfce4-terminal xfce4-panel xfce4-session -y
sudo apt install tigervnc-common -y
sudo apt install x11-xserver-utils -y
sudo apt install lxde -y

nano ~/.vnc/xstartup

  #!/bin/bash
  [ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources

  export XKL_XMODMAP_DISABLE=1

  unset SESSION_MANAGER
  unset DBUS_SESSION_BUS_ADDRESS

  exec startxfce4

chmod +x ~/.vnc/xstartup
adduser vncuser
su - vncuser
vncserver :1

vncserver -list : Should show the running process

ss -tulnp | grep 5901: should display '0.0.0.0:5901'
if it displays 'localhost:5901', configure firewall in the droplet:

  sudo ufw status
  sudo ufw allow 5901/tcp
  sudo ufw reload

(?????)
nano ~/.vnc/config
  localhost=no


3. host machine

vncviewer <DROPLET_PUBLIC_IP>:5901
USER PASSWORD

scp -r 


