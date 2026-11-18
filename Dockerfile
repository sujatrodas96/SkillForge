FROM nginx:alpine
# Update Alpine packages and security patches
RUN apk update && apk upgrade --no-cache

COPY . /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
