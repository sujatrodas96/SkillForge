FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y nginx && apt clean

WORKDIR /var/www/html

RUN rm -rf /var/www/html/*

COPY . /var/www/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]