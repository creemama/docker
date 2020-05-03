FROM nginx:1.17.10-alpine

# Compile https://github.com/openresty/headers-more-nginx-module.

# The `apk add` part except for gnupg comes from the NGINX Docker image:
# https://github.com/nginxinc/docker-nginx/blob/e3bbc1131a683dabf868268e62b9d3fbd250191b/mainline/alpine/Dockerfile.

# To figure out what configure statement built nginx for the Docker image, run
# `nginx -V` as recommended by
# https://github.com/fdintino/nginx-upload-module/issues/103.

RUN apk add --no-cache \
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
 && wget https://nginx.org/download/nginx-1.17.10.tar.gz.asc \
 && wget https://nginx.org/download/nginx-1.17.10.tar.gz \
 && wget https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz \
 && gpg --import mdounin.key \
 && gpg --verify nginx-1.17.10.tar.gz.asc nginx-1.17.10.tar.gz \
 && tar -xzvf v0.33.tar.gz \
 && tar -xzvf nginx-1.17.10.tar.gz \
 && cd nginx-1.17.10 \
 && ./configure \
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --modules-path=/usr/lib/nginx/modules \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --http-client-body-temp-path=/var/cache/nginx/client_temp \
      --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
      --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
      --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
      --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
      --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
      --user=nginx \
      --group=nginx \
      --with-compat \
      --with-file-aio \
      --with-threads \
      --with-http_addition_module \
      --with-http_auth_request_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_mp4_module \
      --with-http_random_index_module \
      --with-http_realip_module \
      --with-http_secure_link_module \
      --with-http_slice_module \
      --with-http_ssl_module \
      --with-http_stub_status_module \
      --with-http_sub_module \
      --with-http_v2_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-stream \
      --with-stream_realip_module \
      --with-stream_ssl_module \
      --with-stream_ssl_preread_module \
      --with-cc-opt='-Os -fomit-frame-pointer' \
      --with-ld-opt=-Wl,--as-needed \
      --add-dynamic-module=$(pwd)/../headers-more-nginx-module-0.33 \
 && make \
 && make install

FROM nginx:1.17.10-alpine

# Organize COPY commands by destination path.
COPY default.conf /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY \
  --from=0 \
  /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so \
  /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so

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
