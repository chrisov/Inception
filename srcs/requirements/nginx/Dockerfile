#
FROM debian:latest

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y nginx
RUN apt-get install -y curl

COPY default /etc/nginx/sites-available/default

CMD ["nginx", "-g", "daemon off;"]