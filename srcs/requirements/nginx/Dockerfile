#
FROM debian:latest

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y nginx

# When copy is uncommented the container doesnt stay alive
# This happens if the files itself doesnt exist?
COPY default /etc/nginx/sites-available/.

CMD ["nginx", "-g", "daemon off;"]