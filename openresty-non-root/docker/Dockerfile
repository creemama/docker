FROM openresty/openresty:1.21.4.1-7-alpine

# Organize COPY commands by destination path.
COPY default.conf /etc/nginx/conf.d/default.conf
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY 404.html /usr/local/openresty/nginx/html/404.html
COPY 50x.html /usr/local/openresty/nginx/html/50x.html

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

# The following is from
# https://github.com/nginxinc/docker-nginx/blob/1.23.2/mainline/alpine-slim/Dockerfile.
RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

USER nginx
