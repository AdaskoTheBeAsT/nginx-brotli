# NGINX with Brotli

Image based on [https://github.com/nginxinc/docker-nginx/blob/master/modules/Dockerfile.alpine](https://github.com/nginxinc/docker-nginx/blob/master/modules/Dockerfile.alpine).
Additionally new NGINX config with enabled Brotli and headers-more modules and removed default files in /usr/share/nginx/html.

Published on [Docker Hub](https://hub.docker.com/repository/docker/adaskothebeast/nginx-brotli).

Usage

```dockerfile
FROM adaskothebeast/nginx-brotli:v1.0.0 AS deploy
```
