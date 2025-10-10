FROM debian:latest

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y mariadb-server

CMD ["mysqld_safe"]