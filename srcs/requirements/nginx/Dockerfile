#
FROM debian:latest

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y nginx

COPY default /etc/nginx/sites-available/.

CMD ["nginx", "-g", "daemon off;"]