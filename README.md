<a name="top"></a>

<div align="center">
  <img src="https://www.dieter-schwarz-stiftung.de/files/Projects/Project%20logos/Logo_42HN-min.jpg" alt="Logo"/>
</div>

<br>
<div align="center">

### 🛠 Docker (Compose)

</div>



# Inception

## Overview

The project creates of a LEMP stack setup, using *Linux* as the host operating system, *Nginx* as the web server to handle HTTP requests, *MariaDB* as the relational database management system and *PHP* as the server side programming language to process requests and generate dynamic content. 

It offers *performance*, as Nginx can handle mulitple concurrent requests, with low memory usage and *flexibility* as it is able to work well with for modern high-traffic websites. 

The project's main components of the setup are explained in the following sections.

<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## Nginx

Nginx is an open source web server and reverse proxy service. 

- It can work as the traffic controller for web requests: deciding what happens when a user’s browser asks for something (like a web page or image).

- It can serve the files directly: when the user is visiting `https://example.com`, Nginx looks for the corresponding .html file and returns it.

- It can also work as *reverse proxy*: forwards requests to another service, such as a backend app.

- It can also handle encryption (TLS/SSL certificates), so that apps don't need to.


### Installation / run

<div align="center">

  | Command                          | Description                                                           |
  |----------------------------------|-----------------------------------------------------------------------|
  | `$ sudo apt install nginx`       | Downaloads and installs Nginx                                         |
  | `$ sudo systemctl start nginx`   | Starts the Nginx service immediately                                  |
  | `$ sudo systemctl enable nginx`  | Ensures Nginx service boots automatically whenever the server reboots |
  | `$ sudo systemctl status nginx`  | Shows if the Nginx service is running and listening on ports          |
  | `$ sudo systemctl restart nginx` | Restarts after config changes                                         |
  | `$ sudo systemctl reload nginx`  | Reloads config without downtime                                       |
  | `$ sudo systemctl stop nginx`    | Stops Nginx service                                                   |

</div>


### Dockerfile

The Dockerfile for Nginx is quite simple:

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/05c9ca967a11cf28b231eb06a3621e936c5bd8cc/srcs/requirements/nginx/dfile.png" width="400" alt="nginx dockerfile"/>
  <br>
  Figure: Nginx Dockerfile
</div>
<br>

This Dockerfile starts the web server and is listening for requests. We can already access it in the local port 80 `https://localhost/80`. If the engine started correctly, we will be able to see a Nginx welcome message! To test it, we build and run the container:

```
$ docker build -t nginx srcs/requirements/nginx/.
$ docker run -d -p 80:80 nginx
```

We have already copied and modified the configuration file `/etc/nginx/sites-available/default`, from inside the container outside, in order to set up the communication with the PHP, by opening up port 9000. After that, we have to replace the original configuration file, with the modified one.

**IMPORTANT**: The Nginx's `-g "daemon off;"` flag sets a global configuration directive from the command line, instead of only from the configuration file (nginx.conf), as it disables Nginx's defaut behavior of running in the background, as a deamon. Instead, with this directive, the process remains in the foreground, so the Docker container can stay alive and running, with it as its main process.


### Configuration

<div align="center">

| Ports               | Logs                                    |
|---------------------|-----------------------------------------|
| 80 (Default HTTP)   | /var/log/nginx/access.log (Access logs) |
| 443 (Default HTTPS) | /var/log/nginx/error.log (Error logs)   |

</div>


<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## Wordpress / PHP

Wordpress is an open source Content Management System (CMS), which basically means that it lets the user build websites and blogs, without coding everything from scratch. It is written in PHP and uses a MySQL/MariaDB database. When a request requires PHP execution (like loading a WordPress page), Nginx passes the request to PHP-FPM (FastCGI Process Manager), then returns the reuslt back to the Nginx, and finally Nginx sends it back to the client.


### Installation / run

| Command                       | Description                     |
|-------------------------------|---------------------------------|
| `$ sudo apt install php-fpm`  | Downaloads and installs PHP-FPM |


### Dockerfile

The Dockerfile for PHP is quite simple:

<div align="center">
  <img src="https://raw.githubusercontent.com/chrisov/Inception/05c9ca967a11cf28b231eb06a3621e936c5bd8cc/srcs/requirements/wordpress/dfile.png" width="400" alt="nginx dockerfile"/>
  <br>
  Figure: Worpress Dockerfile
</div>
  <br>


This Dockerfile starts the container on a PHP image, copies the configuration file from the project's directory into the container, since that file is already properly modified and it will allow the communication with Nginx to happen. 

```
$ docker build -t wordpress srcs/requirements/wordpress/.
$ docker run wordpress
```

  Without proper configuration, the two services (Ngnix, PHP) cannot communicate. To achieve that, we need to acces the PHP-FPM's pool configuration file, `/usr/local/etc/php-fpm.d/www.conf` and set up the communicaton channel in port 9000.

**IMPORTANT**: The PHP's `-F` flag, is used, similarly to Ngnix, to bring the running process on the foreground, so that the container can remain alive and running. WIthout it, the container would start the process and then exit.

### Technical details

aSSSSSSSSSSSSSSSSSSSSSSSSSSSSS

<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## MariaDB

MariaDB is an open source database management system, similar to MySQL in terms of commands and protocols, that the user can use to store, organize, and query structured data in the format of tables, with rows and columns. 

- It can connect data between tables using *primary* (unique IDs) and *foreign* keys (references).

- The user can insert, update delete and fetch data, using *SQL*.

- It can control which user can have access to which database.


### Installation / run

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


### Dockerfile



### Technical details

| SQL Commands | Constraints | Configuration                           |
|--------------|-------------|-----------------------------------------|
| CREATE	   | PRIMARY KEY | /etc/mysql/mariadb.conf.d/50-server.cnf |
| INSERT       | FOREIGN KEY | 3306 (Default Port)                     |
| DELETE
| SELECT
| UPDATE


<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>
