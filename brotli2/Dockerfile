FROM alpine:3.21.3 AS builder

ARG NGINX_VERSION=1.27.4

RUN apk add --no-cache \
  brotli-dev \
  brotli-libs \
  cmake \
  gcc \
  git \
  libc-dev \
  linux-headers \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev

WORKDIR /usr/src

ADD http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz /usr/src/nginx.tar.gz
RUN tar -zxf /usr/src/nginx.tar.gz \
  && git clone https://github.com/openresty/headers-more-nginx-module.git \
  && cd headers-more-nginx-module \
  && git checkout 84a65d68687c9de5166fd49ddbbd68c6962234eb && cd .. \
  && git clone --recurse-submodules https://github.com/google/ngx_brotli.git \
  && cd ngx_brotli \
  && git checkout a71f9312c2deb28875acc7bacfdd5695a111aa53 \
  && git submodule update --init

WORKDIR /usr/src/nginx-${NGINX_VERSION}
RUN ./configure --with-compat --add-dynamic-module=../headers-more-nginx-module \
  --add-dynamic-module=../ngx_brotli --modules-path=/usr/lib/nginx/modules \
  --prefix=/etc/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin/nginx \
  && make modules

FROM nginx:1.27.4-alpine3.21-slim AS runtime

RUN apk add --no-cache brotli-libs

COPY --from=builder /usr/src/nginx-${NGINX_VERSION}/objs/*.so /usr/lib/nginx/modules/
RUN echo "load_module /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so;" > /etc/nginx/modules.conf && \
  echo "load_module /usr/lib/nginx/modules/ngx_http_brotli_static_module.so;" >> /etc/nginx/modules.conf && \
  echo "load_module /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so;" >> /etc/nginx/modules.conf

COPY env.sh /usr/local/bin/env.sh
RUN chmod +x /usr/local/bin/env.sh
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./headers.conf /etc/nginx/conf.d/headers.conf
