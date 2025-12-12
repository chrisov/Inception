FROM debian:bookworm-slim

# Prepare for package installation and cache clean-up
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY init.sh /etc/mariadb/init.sh
RUN chmod +x /etc/mariadb/init.sh

WORKDIR /etc/mariadb
ENTRYPOINT ["./init.sh"]
