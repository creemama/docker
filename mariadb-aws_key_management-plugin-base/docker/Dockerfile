FROM creemama/mariadb-aws_key_management-plugin-build:10.11.2-focal

# https://hub.docker.com/_/mariadb
FROM creemama/mariadb:10.11.2-focal
COPY --from=0 /usr/local/src/server/support-files/rpm/enable_encryption.preset /etc/mysql/conf.d/enable_encryption.preset
COPY encryption.cnf /etc/mysql/conf.d/encryption.cnf

RUN mkdir /home/mysql/ \
 && chown mysql:mysql /home/mysql/ \
 && apt-get -y update \
 && apt-get -y install \
      libcurl4 \
      openssl \
      uuid
USER mysql

# https://serverfault.com/questions/558731/how-to-check-if-mysql-server-is-working-or-not
# $ sh -c "ps aux | egrep '^mysql[ ]+1[ ]+.*mysqld$'"
# mysql        1  0.2  4.2 1924616 86076 ?       Ssl  12:48   0:02 mysqld
# https://web.archive.org/web/20221008015811/https://scalegrid.io/blog/important-health-checks-for-your-mysql-master-slave-servers/
# To add SELECT statements would require creating a test user.
HEALTHCHECK \
  --interval=5m \
  --retries=3 \
  --start-period=1m \
  --timeout=30s \
  CMD pgrep mysqld || exit 1

CMD mysqld \
  --encrypt-binlog=1 \
  --encrypt-tmp-files=1 \
  --plugin-load-add aws_key_management \
  --aws_key_management_key_spec=AES_256 \
  --aws_key_management_log_level=Warn \
  --aws_key_management_master_key_id=alias/mariadb-encryption \
  --aws_key_management_region=us-east-1 \
  --aws_key_management_rotate_key=-1
