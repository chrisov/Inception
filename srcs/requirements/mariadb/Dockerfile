# change to other version
FROM mariadb:11

COPY 50-server.cnf /etc/mysql/conf.d/50-server.cnf
COPY init.sql /docker-entrypoint-initdb.d/init.sql

RUN chown -R mysql:mysql /etc/mysql/conf.d /docker-entrypoint-initdb.d || true
