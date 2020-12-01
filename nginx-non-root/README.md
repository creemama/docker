[![dockeri.co](https://dockeri.co/image/creemama/nginx-non-root)](https://hub.docker.com/r/creemama/nginx-non-root)

# Supported tags and respective `Dockerfile` links

- [`1.18.0-alpine`, `stable-alpine`](https://github.com/creemama/docker/blob/master/nginx-non-root/docker/Dockerfile)

# Running nginx as a non-root user

Compared to the official [nginx images](https://hub.docker.com/_/nginx),
containers created from this nginx image run as the nginx user instead of root.

The page for the official [nginx images](https://hub.docker.com/_/nginx)
made the following recommendations in running nginx as a non-root user, which
this image implements.

Redefine the following directives in [`/etc/nginx/nginx.conf`](https://github.com/creemama/docker/blob/master/nginx-non-root/docker/nginx.conf):

```
pid        /tmp/nginx.pid;
...
http {
    client_body_temp_path /tmp/client_temp;
    proxy_temp_path       /tmp/proxy_temp_path;
    fastcgi_temp_path     /tmp/fastcgi_temp;
    uwsgi_temp_path       /tmp/uwsgi_temp;
    scgi_temp_path        /tmp/scgi_temp;
...
}
```

The image modifies [`/etc/nginx/conf.d/default.conf`](https://github.com/creemama/docker/blob/master/nginx-non-root/docker/default.conf) to run with port 8080 since
non-root users cannot bind processes to port 80 without additional
configuration.

As a security best practice, this image does not advertise nginx or its version
in headers using the following directives.

```
# https://github.com/openresty/headers-more-nginx-module#readme
server_tokens off;
more_clear_headers Server;
```

As recommended by the [Docker Bench for Security](https://github.com/docker/docker-bench-security/blob/master/tests/4_container_images.sh), this image includes a health check.

To disable this health check, do the following:

In [`docker run`](https://docs.docker.com/engine/reference/run/#healthcheck), use `--no-healthcheck`.

In [`docker-compose`](https://docs.docker.com/compose/compose-file/), use:

```
healthcheck:
  disable: true
```

# Trying out nginx-non-root

Use the following Docker command to try out this image:

```
docker run -p 8080:8080 --rm creemama/nginx-non-root:stable-alpine
```

Afterwards, visit [http://localhost:8080](http://localhost:8080) in a browser.

If you check out this container, you can use `docker-compose`:

```
docker-compose up
```

The configuration in [`docker-compose.yml`](https://github.com/creemama/docker/blob/master/nginx-non-root/docker-compose.yml) is a more secure way of running this image.

# Nginx with HTTPS and CAC authentication

For an example server that redirects all traffic to HTTPS, see the [`ssl-example` folder](https://github.com/creemama/docker/blob/master/nginx-non-root/ssl-example). To run this SSL example,
use the following command within the folder:

```
docker-compose up
```

Afterwards, visit [https://localhost:8443](https://localhost:8443) in a browser.

The configuration for OCSP stapling and DoD certificates are
commented out in [default.conf](https://github.com/creemama/docker/blob/master/nginx-non-root/ssl-example/default.conf).

Uncomment the OCSP-stapling section if your certs support it.

Uncomment the Common Access Card (CAC) section if you would like to use CAC authentication with your website. This is useful for securing Department of Defense (DoD) web applications.

We created [self-signed.crt](https://github.com/creemama/docker/blob/master/nginx-non-root/ssl-example/self-signed.crt) and [self-signed.key](https://github.com/creemama/docker/blob/master/nginx-non-root/ssl-example/self-signed.key) using the following command:

```
./self-signed-cert-generate.sh "localhost" "DNS:localhost"
```
