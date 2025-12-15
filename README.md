<a name="top"></a>

<div align="center">
  <img src="https://www.dieter-schwarz-stiftung.de/files/Projects/Project%20logos/Logo_42HN-min.jpg" alt="Logo"/>
</div>

<br>
<div align="center">

### 🛠 Docker (Compose)
### 🛠 SQL

</div>



# Inception

## 1. Overview

The project builds a LEMP stack setup, using *Linux* as the host operating system, *Nginx* as the web server to handle HTTPS requests, *MariaDB* as the relational database management system and *PHP* as the server side programming language to process requests and generate dynamic content. 

It offers *performance*, as Nginx can handle mulitple concurrent requests, with low memory usage and *flexibility* as it is able to work well with for modern high-traffic websites. The stack is deployed as a multicontainer setup with Docker compose, in a DigitalOcean Droplet and accessed remotely.

The project's main components of the setup are explained in the following sections.

<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## 2. Getting Started

### 2.1 Build/run

The Makefile contains several rules that help build and monitor the multicontainer setup. When deplaoying the setup the first time, `make build` will build and run all individual containers in detached mode. Furthermore the following make rules apply:

- `make up`: For running the setup, if already build.
- `make down`: For killing the setup.
- `make re`: For restarting the setup (up + down).
- `make status`: For monitoring containers, volumes and network.
- `make logs`: For monitoring the individual services.
- `make clean`: For reseting the setup in case of configuration modification.
- `make fclean`: For purging the setup (clean + mounted volumes removing): **requires sudo priviledges**.
- `make help`: For listing all available make rules.

**IMPORTANT**: For the first building, it is necessary to wait for 60 seconds for Wordpress to initializa the database and the users. Running `make logs` will creating a directory and store log fles that correspond to the individual services. The one for Wordpress needs to display the successful creation of the database and the users, before accessing the website.

### 2.2 Access

When the setup is up and running, we can then access the website `https://dchrysov.42.fr`. We are prompted to the home page where we can navigate as simple users. `https://dchrysov.42.fr/wp-login.php` prompts the user to login, so that they can interact with it (make comments/posts etc).


### 2.3 Kill

The setup can be killed with either of the corresponding make rules, as mentioned in [Section 2.1](#21-buildrun). It is important to specify the differences between those rules:

  `make down` will just stop service, without affecting the website content.
  `make clean` will stop the service and delete all the mounted volumes in the container side.
  `make fclean` will stop the service and delete all the mounted volumes both in the container and host side (**cannot be restored**)


### 2.4 Docker Compose

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/87d2c2c50c8b231c7f9719c5867badeffa30252e/srcs/requirements/compose.png" width="400" alt="docker compose"/>
  <br>

  ***Figure F2.4.1***: *Docker Compose*

</div>
<br>

The Docker Compose file builds and orchestrates all the services together, so that they are able to communicate with each, through an internal network and provide access to the web server for the host machine.

The Nginx container exposes the port 443, default for HTTPS requests (explained in [Section 3.1](#31-installation--run)). The Wordpress container communicates with Nginx through port 9000 (explained in [Section 3.3](#33-nginx-script-file)). The MariaDB container listens to port 3306, by default, to achieve inter-container communication.

A Bridge Docker network is used to connect all the individual containers together. It creates a private network isolated from both the host network and the internet. This way only the containers in this network can have access to it, providing security and a clean multi container architecture.

Docker Volumes are used for persistent data. Containers are isolated setups by default, meaning that any data stored in the containers would be lost in the case of the setup being stopped/killed. This can be evaded with the utilization of Docker volumes, where specified directories in the host machines can be mounted with directories inside the container, which gives the advantage of safely storing information, even in the case of an untiming killing of the setup.

<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## 3. Nginx

Nginx is an open source web server and reverse proxy service. 

- It can work as the traffic controller for web requests: deciding what happens when a user’s browser asks for something (like a web page or image).

- It can serve the files directly: when the user is visiting `https://example.com`, Nginx looks for the corresponding .html file and returns it.

- It can also work as *reverse proxy*: forwards requests to another service, such as a backend app.

- It can also handle encryption (TLS/SSL certificates), so that apps don't need to.


### 3.1 Installation / Run

<div align="center">

| Command                          | Description    |
|----------------------------------|----------------|
| `$ sudo apt install nginx`       | Installs Nginx |

***Table T3.1.1***: *Nginx intallation command*

</div>
<br>

<div align="center">

| Ports               | Logs                                    |
|---------------------|-----------------------------------------|
| 80 (Default HTTP)   | /var/log/nginx/access.log (Access logs) |
| 443 (Default HTTPS) | /var/log/nginx/error.log (Error logs)   |

  ***Table 3.1.2***: *Configuration details, useful for debugging.*

</div>
<br>


### 3.2 Dockerfile

The Dockerfile for Nginx:

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/dc59c851d54d06cd33472b939f34ae4ce7511249/srcs/requirements/nginx/nginx_df.png" width="400" alt="nginx dockerfile"/>
  <br>
  
  ***Figure F3.2.1***: *Nginx Dockerfile*

</div>
<br>

The Nginx Dockerfile is simple, based on a slim debian version and installing the necessary dependencies. After that, the environment is ready and set to configure the server. This configuration is achieved through the script that is located in the same directory and copied inside the container, with executing permissions, as it contains the configuration details of the server.

### 3.3 Nginx script file

The configuration for the web server is contained in the script file (*init.sh*) that is copied inside the container by the Dockerfile:

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/dc59c851d54d06cd33472b939f34ae4ce7511249/srcs/requirements/nginx/nginx_init.png" width="400" alt="nginx script"/>
  <br>
  
  ***Figure F3.3.1***: *Nginx init.sh*
  
</div>
<br>

The following points explain the script file, line by line:

- `set -e`: sets a flag to the scripts so that if any of the following commands fail, the script exits, so that building a broken service could be avoided.
- `mkdir`: creates the necessary directory to store the security certificates, if not already existing.
- `openssl`: creates the **self-assigned** security certificates. That means that accessing the website for the first time will prompt the user to accept the risks of accessing a website with self-assinged security certificates.
- `cat`: this block will write the following server configuration in the server config file, including the listening port for the server, its name, defining the already made security certificates, as well as a php configuration, necessary for the container's communication with the worpress container, in port 9000, via the fastcgi service.
- `ln`: creation of a symbolic link for the configuration file.
- `exec`: excuting the Nginx daemon.

**IMPORTANT**: The Nginx's `-g "daemon off;"` flag sets a global configuration directive from the command line, instead of only from the configuration file (nginx.conf), as it disables Nginx's defaut behavior of running in the background, as a deamon. Instead, with this directive, the process remains in the foreground, so the container's process can stay alive and running.


### 3.4 Single Container

Running the single container is useful when first setting up the service, to check if there is any misconfiguration in the Dockerfile. In the case of the Nginx service, we don't want to copy any configuration file back into the container, as this will override any default global instructions and make the container listen for the wp-php's container's port 9000.

If we uncomment that part (*lines 9, 10*), and replace the parameter in the CMD command with `CMD ["nginx", "-g daemon off;"]` (same as the init.sh), the container can stay alive and running and we can then check for the specific port in the localhost for Nginx's welcome message. Otherwise the container's creation will **fail**. To test it, we build and run the container:

```
bash
$ docker build -t nginx <PATH_TO_DOCKERFILE>
$ docker run -d -p 8080:80 nginx
```

This Dockerfile starts the web server and is listening for requests. We can already access it in the local port 8080 `http://localhost:8080`. If the engine started successfully, we will be able to see a Nginx welcome message!



<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## 4. Wordpress / PHP

Wordpress is an open source Content Management System (CMS), which basically means that it lets the user build websites and blogs, without coding everything from scratch. It is written in PHP and uses a MySQL/MariaDB database. When a server request requires PHP execution (like loading a WordPress page), Nginx passes the request to PHP-FPM (FastCGI Process Manager), then returns the result back to the Nginx, and finally Nginx sends it back to the client.


### 4.1 Installation / run

<div align="center">
  
| Command                             | Description                                |
|-------------------------------------|--------------------------------------------|
| `$ apt install php8.2-fpm`          | Installs PHP-FPM                           |
| `$ apt install php8.2-mysql`        | Installs the PHP MySQL extension           |
| `$ apt install apt-transport-https` | Enable HTTPS Support                       |
| `$ apt install ca-certificates`     | Trust Secure Connections                   |
| `$ apt install lsb-release`         | Identify the OS                            |
| `$ apt install wget`                | Download Tool                              |
| `$ wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg` | Download and Trust the Key                                                         |
| `$ echo "..."`                      | Add the Repository URL                     |

  ***Table T4.1.1***: *Wordpress Dockerfile dependencies.*
  
</div>
<br>


### 4.2 Dockerfile

The Dockerfile for WP-PHP:

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/dc59c851d54d06cd33472b939f34ae4ce7511249/srcs/requirements/wordpress/wp_df.png" width="700" alt="wp Dockerfile"/>
  <br>
  
  ***Figure F4.2.1***: *WP-PHP Dockerfile*
  
</div>
  <br>


Without proper configuration, the two services (Ngnix, PHP) cannot communicate. To achieve that, we need to access the PHP-FPM's pool configuration file `/etc/php/8.2/fpm/pool.d/www.conf` and set up the communicaton channel in port 9000. After that we can safely copy it back in the container.

This Dockerfile starts the container on a PHP image, copies the configuration file from the project's directory into the container, since that file is already properly modified and it will allow the communication with Nginx to happen. Finally, it will configure the FPM instance, through the *init.sh* file.

### 4.3 WP-PHP script file

The configuration for the WP-PHP instance is contained in the script file (*init.sh*) that is copied inside the container by the Dockerfile:

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/dc59c851d54d06cd33472b939f34ae4ce7511249/srcs/requirements/wordpress/wp_init.png" width="400" alt="wp-php script"/>
  <br>
  
  ***Figure F4.3.1***: *WP-PHP init.sh*
  
</div>
<br>

The following points explain the script file, line by line:

- `set -e`: reference [Section 3.3](#33-nginx-script-file).
- `cd`: change into the wp-php config directory.
- `if...fi`: Downloads the WP-CLI if not already existing.
- `if...fi`: Downloads the WP core, if not already existing, and creates the database as well as the admin user, based on the credentials in the *.env* file.
- `exec`: executes the wp-php service.

**IMPORTANT**: The PHP's `-F` flag, is used, similarly to Ngnix, to bring the running process on the foreground, so that the container can remain alive and running. Without it, the container would start the process and then exit.

### 4.4 Double Containers

As was the case for Nginx, to run a single wp-php container, in combination with the Nginx service of course, we need to configure the default global configurations, to make it listen for the appropriate port.

Create a custom test network for both of the container to communicate through:

```
bash
$ docker network create <NETWORK_NAME>
```

Modify the www.conf file to listen to any IP in the network `listen = 0.0.0.0:9000` (the network is only gonna include the two containers). Modify the command in the Dockerfile to call the executable in the foreground `CMD ["/usr/sbin/php-fpm8.2", "-F"]`, then build the container, commenting out the lines that correspond to the running script (line 23, 24):

```
bash
$ docker build -t wp-php-simple <PATH_TO_DOCKERFILE>
```

Run the container with a few parameters:

```
bash
$ docker run -d --network <NETWORK_NAME> --volume "$(pwd)/../web/":/var/www/html/ wp-php-simple
```

Extract the IP Address of the running container:

```
bash
$ docker inspect -f <CONT_NAME> | grep "IP"
```

Modify the nginx default configuration file to use that same IP address `fastcgi_pass <IP_ADDRESS>:9000` as the wp-php container.
Build and run the Nginx container with the appropriate parameters:

```
bash
$ docker build -t nginx <PATH_TO_DOCKERFILE>
$ docker run -d --network <NETWORK_NAME> --volume "$(pwd)/../web/":/var/www/html/ -p 8080:80 nginx
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

The Dockerfile for MariaDB is also simple enough:

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/dc59c851d54d06cd33472b939f34ae4ce7511249/srcs/requirements/mariadb/mariadb_df.png" width="400" alt="MariaDB Dockerfile"/>
  <br>
  
  ***Figure F5.2.1***: *MariadDB Dockerfile*
  
</div>
<br>

It is built upon the same lightweight debian image and apart from installing all the necessary dependencies, it copies the configuration script to the appropriate file path, set with executable permissions and finally runs it.


### 5.3 MariaDB script file

The configuration script necessary to run the mariadb service creates and sets up the database.

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/dc59c851d54d06cd33472b939f34ae4ce7511249/srcs/requirements/mariadb/mariadb_init.png" width="400" alt="wp-php script"/>
  <br>
  
  ***Figure F5.3.1***: *MariaDB init.sh*
  
</div>
<br>

A line by line explanation follows:

- `set -e`: reference [section 3.3](#33-nginx-script-file).
- `FILE`: define the configuration file.
- `sed`: create the socket.
- `mkdir`: create the directory to install the mysql service.
- `chown`: change the ownership
- `if...fi`: initialize the data directory, if not already existing.
- `mysqld_safe`: runs mysql service in safe mode, without access to the internet for safe initialization.
- `for...`: loop that waits max 1 min for the socket to become available.
- `mysql`: run mysql as root and create the database and the admin user, based on the credentials provided in the .env file.
- `mysql`: run mysql as root again and create a regular user, based on the credentials provided in the .env file.
- `mysqladmin`: shut the socket down.
- `exec`: run the mysql service.

### 5.4 Single Container

The same Dockerfile can be used, as is, to run the container on its own. The same configuration will be installed and therefore will be possible to access it and run the mariadb service. For that, access the container's terminal with:

1. 
    ```
    bash
    $ docker exec -it mariadb bash  # The prompt should be different now
    ```

2. 
    ```
    bash
    $ mariadb -uroot -p'$<MYSQL_ROOT_PASSWORD> # Access as Admin user
    ```

    **OR**

    ```
    bash
    $ mariadb -u<MYSQL_USER> -p'<MYSQL_PASS>`   # Access as regular user
    ```


If entered successfully, the terminal prompts a MariaDB welcome message. From then on, it is possible to execute MySQL queries. An example is given, to fully display a table:

```
SHOW DATABASES;
CONNECT <DATABASE_NAME>
SHOW TABLES
SELECT * FROM <TABLE_NAME>
```

### 5.5 SQL Queries

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

## 6. Cloud Virtual Machine

For this implementation, the DigitalOcean Cloud service was used, to create a Linux droplet and install a remote desktop.

*NOTE*: A student Github account can provide 200$ worth of credits, which is more than enough for building and evaluating this project. Unless one chooses one of the expensive packages, with the many resources, although unecessary.

### 6.1 Installation

1. The droplet may be built upon any Linux image, in this implementation Ubuntu was used. Connect with ssh to the Droplet's terminal by:

    ```
    bash
    $ ssh root@<DROPLET_PUBLIC_IP>
    ```

2. Install the necessary dependencies:

    ```
    bash
    $ sudo apt update && sudo apt upgrade -y
    $ sudo apt update
    $ sudo apt install xubuntu-desktop -y
    $ sudo apt install xfce4 xfce4-goodies tigervnc-standalone-server x11-xserver-utils xterm dbus-x11 -y
    $ sudo apt install xfce4-terminal xfce4-panel xfce4-session -y
    $ sudo apt install tigervnc-common -y
    $ sudo apt install x11-xserver-utils -y
    $ sudo apt install lxde -y
    ```

3. Create the interactive environment script:

    ```
    bash
    $ nano ~/.vnc/xstartup
    ```

    ```
    #!/bin/bash
    [ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources

    export XKL_XMODMAP_DISABLE=1

    unset SESSION_MANAGER
    unset DBUS_SESSION_BUS_ADDRESS

    exec startxfce4
    ```

    *NOTE*: Create the .vnc directory if it's not already existing.

4. Give the script execute permissions: 

    ```
    bash
    $ chmod +x ~/.vnc/xstartup
    ```

5. Create a new user (same as the 42 login name):

    ```
    bash
    $ adduser <USERNAME>
    ```

6. Give the new user sudo priviledges:

    ```
    bash
    $ sudo usermod -aG sudo <USERNAME>
    ```

7. Exit ssh for the new settings to be applied and login again as the new user

    ```
    bash
    $ ssh <USERNAME>@<DROPLET_PUBLIC_IP>
    ```

    *NOTE*: A slight wait me be necessary before launching ssh again (< 1 min).

8. Install the remote server service:

    ```
    bash
    $ sudo apt install vncserver -y
    ```

9.  Start the remote server:

    ```
    bash
    $ vncserver -list                 # Should display no active servers.
    $ vncserver :1 -localhost no
    $ vncserver -list                 # Should display 1 active server.
    ```

    *NOTE*: The flag sets the server to be accessible outside of localhost, necessary for accessing it from the host machine. The :1 opens the first port available to the server. By default the server starts counting from 5900, so in this case the active server should be accessed through the 5901 port.

10. Check firewall accessibility:

    ```
    bash
    $ ss -tulnp | grep 5901           # Should display '0.0.0.0:5901'
    ```

    *NOTE*: if it displays 'localhost:5901', configure firewall in the droplet:

    ```
    bash
    $ sudo ufw status
    $ sudo ufw allow 5901/tcp
    $ sudo ufw reload
    ```

11. Open a new terminal on the host machine and run the remote Desktop:

    ```
    bash
    $ vncviewer <DROPLET_PUBLIC_IP>:<5901>
    ```

12.  The remote Desktop window should be up and running. It will be necessary to install firefox, Docker (and VSCode ?):

    ```
    bash
    $ sudo apt update
    $ sudo apt upgrade -y
    ```

13. Install Firefox:

    ```
    bash
    $ sudo snap remove firefox
    $ sudo apt purge firefox
    $ cd opt/
    $ sudo wget 'https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US' -O firefox.tar.bz2
    $ sudo tar xJf firefox.tar.bz2
    $ sudo ln -s /opt/firefox/firefox /usr/local/bin/firefox
    $ firefox &
    ```

14. Install Docker:

    ```
    bash
    $ sudo apt remove docker docker-engine docker.io containerd runc
    $ sudo apt update
    $ sudo apt install -y ca-certificates curl gnupg lsb-release
    $ sudo mkdir -p /etc/apt/keyrings
    $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $ echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    $ sudo apt update
    $ sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    $ sudo usermod -aG docker $USER
    $ newgrp docker
    $ docker --version
    $ docker run hello-world
    ```

15. Install VSCode

    ```
    bash
    $ sudo snap install code --classic
    ```


<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

14. Restart ssh

### 6.2 Access

To access the droplet, after finish configuring it, one needs to follow Steps 7, 9 and 11.

### 6.3. Useful Commands

- During the evaluation process, cloning vogsphere directly in the cloud would not be possible, therefore cloning it in the host machine and copying the repo in the VM is the only way. For that, a secure copy command should be executed:

  ```
  bash
  $ scp -r <SOURCE_DIRECTORY> <USERNAME>@<DROPLET_PUBLIC_IP:<TARGET_DIRECTORY>
  ```

- During the evaluation process, it will be necessary to prove that the website is rejecting the http requests. This will be impossible to do through the browser directly, because firefox redirects the http requests to https by default. Therefore, the following command can be useful to prove this point:

  ```
  bash
  $ curl -v -4 --connect-timeout 3 http://dchrysov.42.fr # Should diplay 'connection refused'
  ```

  ```
  bash
  $ curl -v -4 --connect-timeout 3 https://dchrysov.42.fr # Should diplay the connection's details
  ```


<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>