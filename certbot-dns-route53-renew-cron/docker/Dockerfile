FROM certbot/dns-route53:v1.11.0

COPY certbot-renew.py /usr/local/bin/certbot-renew.py
COPY certbot-non-root.sh /usr/local/bin/certbot-non-root

# https://pypi.org/project/pip/
# https://pypi.org/project/schedule/
RUN addgroup -g 1000 certbot \
 && adduser -D -G certbot -s /bin/sh -u 1000 certbot \
 && apk add --no-cache --update tini~=0.19 \
 && pip install --upgrade pip==20.3.3 \
 && pip install --upgrade schedule==0.6.0

USER certbot
WORKDIR /home/certbot

# We use a 4-hour interval because we really do not need to waste energy
# checking if this container is healthy when we only check for certificate
# renewal twice a day.
HEALTHCHECK --interval=4h CMD certbot -h || exit 1
ENTRYPOINT ["tini", "--"]
CMD ["certbot-renew.py"]
