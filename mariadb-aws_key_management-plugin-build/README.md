[![dockeri.co](https://dockeri.co/image/creemama/mariadb-aws_key_management-plugin-build)](https://hub.docker.com/r/creemama/mariadb-aws_key_management-plugin-build)

# Supported tags and respective `Dockerfile` links

- [`10.5.8-focal`, `latest`](https://github.com/creemama/docker/blob/master/mariadb-aws_key_management-plugin-build/docker/Dockerfile)

# The AWS Key Management Plugin for MariaDB

These Docker images build the AWS Key Management Plugin from source. The
resulting `aws_key_management.so` is compatible with the [Docker official
images for MariaDB](https://hub.docker.com/_/mariadb).

To make `aws_key_management.so`, do the following:

```
docker run --name aws_key_management_build creemama/mariadb-aws_key_management-plugin-build:latest
docker cp aws_key_management_build:/usr/local/src/build-mariadb/plugin/aws_key_management/aws_key_management.so .
```

The AWS Key Management Plugin is no longer available from the APT repo.
According to a [MariaDB bug
report](https://jira.mariadb.org/browse/MDEV-18752?focusedCommentId=123862&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-123862),
the "plugin uses (and is linked with) AWS C++ SDK, which is available under the
Apache 2.0 license. And this license it not compatible with GPLv2."

When building MariaDB with the AWS Key Management Plugin, the build output
warns that "You have linked MariaDB with GPLv3 libraries! You may not
distribute the resulting binary. If you do, you will put yourself into a
legal problem with the Free Software Foundation." Note that Apache 2.0 is
[GPLv3
compatible](https://en.wikipedia.org/wiki/Apache_License#GPL_compatibility).

To use the `aws_key_management.so` library created by this image in a MariaDB
image (not for distribution), you could do the folllowing:

```
FROM creemama/mariadb-aws_key_management-plugin-build:latest
RUN make aws_key_management

FROM mariadb:latest
COPY \
  --from=0 \
  /usr/local/src/build-mariadb/plugin/aws_key_management/aws_key_management.so \
  /usr/lib/mysql/plugin/aws_key_management.so
COPY \
  --from=0 \
  /usr/local/src/server/debian/additions/enable_encryption.preset \
  /etc/mysql/conf.d/enable_encryption.preset
RUN usermod -d /var/lib/mysql/ mysql \
 && apt-get -y update \
 && apt-get -y install \
      libcurl4 \
      openssl \
      uuid \
 && printf "%s\n" "[mariadb]"                                             >> /etc/mysql/conf.d/encryption.cnf \
 && printf "%s\n" "!include /etc/mysql/conf.d/enable_encryption.preset"   >> /etc/mysql/conf.d/encryption.cnf \
 && printf "%s\n" "innodb_encrypt_log = ON"                               >> /etc/mysql/conf.d/encryption.cnf \
 && printf "%s\n" "innodb_encrypt_tables = FORCE"                         >> /etc/mysql/conf.d/encryption.cnf \
 && printf "%s\n" "innodb_encryption_threads = 4"                         >> /etc/mysql/conf.d/encryption.cnf \
 && printf "%s\n" "ssl_ca = /run/secrets/mariadb-ca"                      >> /etc/mysql/conf.d/encryption.cnf \
 && printf "%s\n" "ssl_cert = /run/secrets/mariadb-server-cert"           >> /etc/mysql/conf.d/encryption.cnf \
 && printf "%s\n" "ssl_key = /run/secrets/mariadb-server-key"             >> /etc/mysql/conf.d/encryption.cnf

USER mysql

CMD mysqld \
  --encrypt-binlog=1 \
  --encrypt-tmp-files=1 \
  --plugin-load-add aws_key_management \
  --aws_key_management_key_spec=AES_256 \
  --aws_key_management_log_level=Warn \
  --aws_key_management_master_key_id=alias/mariadb-encryption \
  --aws_key_management_region=us-east-1 \
  --aws_key_management_rotate_key=-1
```

For how to build and set up the AWS Key Management Plugin from source, the
following articles are helpful:

- ["AWS Key Management Encryption
  Plugin"](https://mariadb.com/kb/en/library/aws-key-management-encryption-plugin/)
- ["Build Environment Setup for
  Linux"](https://mariadb.com/kb/en/library/Build_Environment_Setup_for_Linux/)
- ["Amazon Web Services (AWS) Key Management Service (KMS) Encryption Plugin
  Setup
  Guide"](https://mariadb.com/kb/en/library/aws-key-management-encryption-plugin-setup-guide/)
- ["Encrypting MariaDB on Ubuntu
  16.04"](https://medium.com/@acurrieclark/encrypting-mariadb-e3b434170910)
