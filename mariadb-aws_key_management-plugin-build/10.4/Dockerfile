FROM ubuntu:bionic

RUN printf "%s\n" "deb-src http://security.ubuntu.com/ubuntu/ bionic-security universe" \
 >> /etc/apt/sources.list \
 && apt-get -y update \
 && apt-get -y build-dep mariadb-server \
 && apt-get -y install \
      git \
      gnutls-dev \
      libcurl3-dev \
      libssl-dev \
      uuid-dev \
 && cd /usr/local/src \
 && git clone \
      --branch mariadb-10.4.6 \
      --depth 1 \
      https://github.com/MariaDB/server.git \
 && mkdir build-mariadb \
 && cd build-mariadb \
 && cmake \
      -DPLUGIN_AWS_KEY_MANAGEMENT=DYNAMIC \
      -DAWS_SDK_EXTERNAL_PROJECT=1 \
      -DNOT_FOR_DISTRIBUTION=1 \
      ../server

WORKDIR /usr/local/src/build-mariadb

CMD sh -c "make aws_key_management && printf '\n\n%s\n%s\n\n%s\n\n' \
      'To get the built aws_key_management.so library, execute the following ' \
      'replacing container-name as appropriate:' \
      'docker cp container-name:/usr/local/src/build-mariadb/plugin/aws_key_management/aws_key_management.so .'"
