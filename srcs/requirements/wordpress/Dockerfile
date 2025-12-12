#
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

#  Install dependencies
RUN apt update
RUN apt install -y apt-transport-https
RUN apt install -y ca-certificates
RUN apt install -y lsb-release
RUN apt install -y wget
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list

RUN apt update
RUN apt install -y php8.2-fpm
RUN apt install -y php8.2-mysqli
RUN apt install -y curl
RUN rm -rf /var/lib/apt/lists/*

COPY www.conf /etc/php/8.2/fpm/pool.d/.

COPY script.sh .
RUN chmod +x script.sh

CMD ["./script.sh"]