################# Build #################
FROM adaskothebeast/node-build:v1.2.0 AS build

# create and change app folder
WORKDIR /app

# copy inly files necessary for node packages restore
COPY package.json yarn.lock check-libs.js ./
#COPY ./patches ./patches

# restore with lockfile - less frequent layer rebuild
RUN yarn install --frozen-lockfile

# copy whole content to build
COPY . .

# patch libs with patches folder
#RUN yarn postinstall

# build all
RUN yarn build && \
  yarn test && \
  yarn lint

#RUN yarn stylelint:ci:json:docker

#RUN yarn htmlhint:ci:html:docker

################# Final #################
FROM adaskothebeast/nginx-brotli:v1.27.14-slim AS deploy

ENV uri=\$uri

WORKDIR /var/www
COPY --from=build /app/dist/apps/ui .
COPY ./.env .

# Create user
RUN adduser -D -g 'www' www

# Set permissions
RUN mkdir -p /template \
  && mkdir -p /var/lib/nginx \
  && chown -R www:www /etc/nginx \
  && chown -R www:www /var/lib/nginx \
  && chown -R www:www /var/cache/nginx \
  && chown -R www:www /var/www \
  && chown -R www:www /tmp \
  && chmod -R 770 /tmp

VOLUME ["/var/cache/nginx"]

# Expose server ports
EXPOSE 8080

# export command exports given env variable to be visible
# highly inspired by two articles
# https://developers.redhat.com/blog/2021/03/04/making-environment-variables-accessible-in-front-end-containers#conclusion
# in comments there is information about "sponge"
# https://github.com/joellord/frontend-containers/blob/main/envvars.md
# https://github.com/joellord/frontend-containers/blob/main/rootless.md
# https://github.com/joellord/frontend-containers/tree/main/react-project
# script modifies env-config.js file
# and also CONTENT_SECURITY_POLICY in headers.conf
ENTRYPOINT ["sh", "-c", "export API_BASE_URL \
  && export APP_TENANT_ID \
  && export APP_CLIENT_ID \
  && export API_SCOPES \
  && /usr/local/bin/env.sh API APP \
  && nginx -g 'daemon off;'"]
USER www
