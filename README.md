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

Nginx is an open source web server and reverse proxy. It can work as the traffic controller for web requests: deciding what happens when a user’s browser asks for something (like a web page or image).

- It can serve the files directly, when the user is visiting `https://example.com`, Nginx looks for the corresponding .html file and returns it.

- It can also work as *reverse proxy*, to forward requests to another service, such as a backend app, it sends that request to the corresponding service.

- It can also handle encryption (TLS/SSL certificates), so that apps don't need to.

### Technical details

| Ports               | Logs                                    |
|---------------------|-----------------------------------------|
| 80 (Default HTTP)   | /var/log/nginx/access.log (Access logs) |
| 443 (Default HTTPS) | /var/log/nginx/error.log (Error logs)   |


### Installation / run

| Command                          | Description                                                           |
|----------------------------------|-----------------------------------------------------------------------|
| `$ sudo apt install nginx`       | Downaloads and installs Nginx                                         |
| `$ sudo systemctl start nginx`   | Starts the Nginx service immediately                                  |
| `$ sudo systemctl enable nginx`  | Ensures Nginx service boots automatically whenever the server reboots |
| `$ sudo systemctl status nginx`  | Shows if the Nginx service is running and listening on ports          |
| `$ sudo systemctl restart nginx` | Restarts after config changes                                         |
| `$ sudo systemctl reload nginx`  | Reloads config without downtime                                       |
| `$ sudo systemctl stop nginx`    | Stops Nginx service                                                   |



<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>

## MariaDB

MariaDB is an open source database management system, similar to MySQL in terms of commands and protocols, that the user can use to store, organize, and query structured data in the format of tables, with rows and columns. 

- It can connect data between tables using *primary* (unique IDs) and *foreign* keys (references).

- The user can insert, update delete and fetch data, using *SQL*.

- It can control which user can have access to which database.


### Technical details

| SQL Commands | Constraints | Configuration                           |
|--------------|-------------|-----------------------------------------|
| CREATE	   | PRIMARY KEY | /etc/mysql/mariadb.conf.d/50-server.cnf |
| INSERT       | FOREIGN KEY | 3306 (Default Port)                     |
| DELETE
| SELECT
| UPDATE


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


<div align="right">
  <a href="#top">⬆️ Return to top</a>
</div>

<br>


## Wordpress

Nginx cannot handle PHP scripts directly 	