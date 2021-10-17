FROM nginx:1.20.1-alpine

# Compile https://github.com/openresty/headers-more-nginx-module.

# The `apk add` part except for gnupg comes from the NGINX Docker image:
# https://github.com/nginxinc/docker-nginx/blob/e3bbc1131a683dabf868268e62b9d3fbd250191b/mainline/alpine/Dockerfile.

# To figure out what configure statement built nginx for the Docker image, run
# `nginx -V` as recommended by
# https://github.com/fdintino/nginx-upload-module/issues/103.

# We use eval here because of --with-cc-opt='-Os -fomit-frame-pointer'. If we do
# not use eval, we get the following error:
# ./configure: error: invalid option "-fomit-frame-pointer'"
# See
# https://stackoverflow.com/questions/39585662/bash-shell-expand-arguments-with-spaces-from-variable/39586326 .

RUN set -o xtrace \
 && apk add --no-cache \
      gcc \
      gnupg \
      libc-dev \
      make \
      openssl-dev \
      pcre-dev \
      zlib-dev \
      linux-headers \
      libxslt-dev \
      gd-dev \
      geoip-dev \
      perl-dev \
      libedit-dev \
      mercurial \
      bash \
      alpine-sdk \
      findutils \
 && wget https://nginx.org/keys/mdounin.key \
 && wget https://nginx.org/download/nginx-1.20.1.tar.gz.asc \
 && wget https://nginx.org/download/nginx-1.20.1.tar.gz \
 && wget https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz \
 && gpg --import mdounin.key \
 && gpg --verify nginx-1.20.1.tar.gz.asc nginx-1.20.1.tar.gz \
 && tar -xzvf v0.33.tar.gz \
 && tar -xzvf nginx-1.20.1.tar.gz \
 && cd nginx-1.20.1 \
 && eval ./configure $(nginx -V 2>&1 | grep 'configure arguments: ' | sed 's/configure arguments: //') \
      --add-dynamic-module=$(pwd)/../headers-more-nginx-module-0.33 \
 && make \
 && make install

FROM nginx:1.20.1-alpine

# Organize COPY commands by destination path.
COPY default.conf /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY \
  --from=0 \
  /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so \
  /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so
COPY 404.html /usr/share/nginx/html/404.html
COPY 50x.html /usr/share/nginx/html/50x.html

# From
# https://github.com/docker/docker-bench-security/blob/master/tests/4_container_images.sh,
# Docker Bench for Security recommends "Ensur[ing] that HEALTHCHECK
# instructions have been added to container images."

# From
# https://www.gnu.org/software/wget/manual/html_node/Download-Options.html,
# "When invoked with [--spider], Wget will behave as a Web spider, which means
# that it will not download the pages, just check that they are there.

# To disable this health check do the following:

# https://docs.docker.com/engine/reference/run/#healthcheck
# In `docker run`, use --no-healthcheck.

# https://docs.docker.com/compose/compose-file/
# In docker-compose, use:
# healthcheck:
#   disable: true

HEALTHCHECK \
  --interval=5m \
  --retries=3 \
  --start-period=1m \
  --timeout=30s \
  CMD wget -q --spider http://localhost:8080 || exit 1

USER nginx
