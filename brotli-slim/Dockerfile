ARG NGINX_VERSION=1.27.3

FROM nginx:${NGINX_VERSION}-alpine-slim AS builder

RUN apk add --no-cache \
  nginx-mod-http-brotli \
  nginx-mod-http-headers-more

COPY env.sh /usr/local/bin/env.sh
RUN chmod +x /usr/local/bin/env.sh
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./headers.conf /etc/nginx/conf.d/headers.conf

RUN rm -rf /usr/share/nginx/html/*
