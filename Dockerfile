FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

RUN \
  echo "**** Add nginx repository ****" && \
  curl https://nginx.org/keys/nginx_signing.key > /etc/apt/trusted.gpg.d/nginx.asc && \
  echo "deb http://nginx.org/packages/ubuntu jammy nginx" > /etc/apt/sources.list.d/nginx.list && \
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
    php8.1 \
    php8.1-fileinfo \
    php8.1-fpm \
    php8.1-mbstring \
    php8.1-simplexml \
    php8.1-xml \
    php8.1-xmlwriter && \
  echo "**** configure nginx ****" && \
  echo 'fastcgi_param  HTTP_PROXY         ""; # https://httpoxy.org/' >> \
    /etc/nginx/fastcgi_params && \
  echo 'fastcgi_param  PATH_INFO          $fastcgi_path_info; # http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_split_path_info' >> \
    /etc/nginx/fastcgi_params && \
  echo 'fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name; # https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/#connecting-nginx-to-php-fpm' >> \
    /etc/nginx/fastcgi_params && \
  echo 'fastcgi_param  SERVER_NAME        $host; # Send HTTP_HOST as SERVER_NAME. If HTTP_HOST is blank, send the value of server_name from nginx (default is `_`)' >> \
    /etc/nginx/fastcgi_params && \
  rm -f /etc/nginx/http.d/default.conf && \
  rm -f /etc/nginx/conf.d/* && \
  echo "**** configure php ****" && \
  sed -i "s#error_log = /var/log/php8.1-fpm.log.*#error_log = /config/log/php/error.log#g" \
    /etc/php/8.1/fpm/php-fpm.conf && \
  sed -i "s#user = www-data.*#user = abc#g" \
    /etc/php/8.1/fpm/pool.d/www.conf && \
  sed -i "s#group = www-data.*#group = abc#g" \
    /etc/php/8.1/fpm/pool.d/www.conf && \
  sed -i "s#listen.owner = www-data.*#user = abc#g" \
    /etc/php/8.1/fpm/pool.d/www.conf && \
  sed -i "s#listen.group = www-data.*#group = abc#g" \
    /etc/php/8.1/fpm/pool.d/www.conf && \
  sed -i "s#listen = .*#listen = 127.0.0.1:9000#g" \
    /etc/php/8.1/fpm/pool.d/www.conf && \
  echo "**** fix logrotate ****" && \
  sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
    /etc/cron.daily/logrotate && \
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
