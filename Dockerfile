# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="pagdot version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="pagdot"

RUN \
  echo "**** Add nginx repository ****" && \
  curl https://nginx.org/keys/nginx_signing.key > /etc/apt/trusted.gpg.d/nginx.asc && \
  echo "deb http://nginx.org/packages/ubuntu noble nginx" > /etc/apt/sources.list.d/nginx.list && \
  echo "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx && \
  apt update && \
  echo "**** install build packages ****" && \
  apt install -y \
    apache2-utils \
    git \
    curl \
    patch \
    logrotate \
    nano \
    nginx \
    openssl \
    php8.3 \
    php8.3-curl \
    php8.3-fileinfo \
    php8.3-fpm \
    php8.3-mbstring \
    php8.3-simplexml \
    php8.3-xml \
    php8.3-xmlwriter \
    php8.3-zip && \
  echo "**** configure nginx ****" && \
  echo 'fastcgi_param  HTTP_PROXY         ""; # https://httpoxy.org/' >> \
    /etc/nginx/fastcgi_params && \
  echo 'fastcgi_param  PATH_INFO          $fastcgi_path_info; # http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_split_path_info' >> \
    /etc/nginx/fastcgi_params && \
  echo 'fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name; # https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/#connecting-nginx-to-php-fpm' >> \
    /etc/nginx/fastcgi_params && \
  echo 'fastcgi_param  SERVER_NAME        $host; # Send HTTP_HOST as SERVER_NAME. If HTTP_HOST is blank, send the value of server_name from nginx (default is `_`)' >> \
    /etc/nginx/fastcgi_params && \
  rm -f /etc/nginx/conf.d/stream.conf && \
  rm -f /etc/nginx/http.d/default.conf && \
  rm -f /etc/nginx/conf.d/* && \
  echo "**** guarantee correct php version is symlinked ****" && \
  if [ "$(readlink /usr/bin/php)" != "php83" ]; then \
    rm -rf /usr/bin/php && \
    ln -s /usr/bin/php83 /usr/bin/php; \
  fi && \
  echo "**** configure php ****" && \
  sed -i "s#error_log = /var/log/php8.3-fpm.log.*#error_log = /config/log/php/error.log#g" \
    /etc/php/8.3/fpm/php-fpm.conf && \
  sed -i "s#user = www-data.*#user = abc#g" \
    /etc/php/8.3/fpm/pool.d/www.conf && \
  sed -i "s#group = www-data.*#group = abc#g" \
    /etc/php/8.3/fpm/pool.d/www.conf && \
  sed -i "s#listen.owner = www-data.*#user = abc#g" \
    /etc/php/8.3/fpm/pool.d/www.conf && \
  sed -i "s#listen.group = www-data.*#group = abc#g" \
    /etc/php/8.3/fpm/pool.d/www.conf && \
  sed -i "s#listen = .*#listen = 127.0.0.1:9000#g" \
    /etc/php/8.3/fpm/pool.d/www.conf && \
  echo "**** install php composer ****" && \
  EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')" && \
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")" && \
  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then \
      >&2 echo 'ERROR: Invalid installer checksum' && \
      rm composer-setup.php && \
      exit 1; \
  fi && \
  php composer-setup.php --install-dir=/usr/bin && \
  rm composer-setup.php && \
  ln -s /usr/bin/composer.phar /usr/bin/composer && \
  echo "**** fix logrotate ****" && \
  sed -i "s#/var/log/messages {}.*# #g" \
    /etc/logrotate.conf && \
  sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
    /etc/cron.daily/logrotate && \
  echo "**** Patch banner ****" && \
  curl https://gist.githubusercontent.com/pagdot/64e28eb0ea68f502f3ead439ae07c249/raw/447bc60a9a7191e70d146cfcdf3996046ae63f41/lsio_pagdot_banner.patch \
    | patch -p1 /etc/s6-overlay/s6-rc.d/init-adduser/run && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
