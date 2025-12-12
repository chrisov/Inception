#
FROM debian:bookworm-slim

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y nginx
RUN apt-get install -y curl

COPY init.sh /init.sh
RUN chmod +x ./init.sh

ENTRYPOINT ["/init.sh"]