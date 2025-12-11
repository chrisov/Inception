# change to other version
FROM debian:latest

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y mariadb-server

COPY 50-server.cnf /etc/mysql/mariadb.conf.d/.
COPY init.sql etc/mysql/init.sql
COPY script.sh .

RUN mkdir /run/mysqld
RUN chmod +x script.sh

CMD ["./script.sh"]