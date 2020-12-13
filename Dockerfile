FROM ubuntu:18.04

ARG PHP_VERSION=7.3
ARG PHPMYADMIN=4.9.7
ARG TIMEZONE_AREA="Europe"
ARG TIMEZONE_CITY="Stockholm"

COPY ./scripts/autoclean.sh /root/
COPY ./scripts/docker-entrypoint.sh ./misc/cronfile.final ./misc/cronfile.system ./scripts/build.sql /

RUN echo ${PHP_VERSION} > /PHP_VERSION; \
chmod +x /root/autoclean.sh; \
chmod +x /docker-entrypoint.sh; \
mkdir /run/php/;

ENV DEBIAN_FRONTEND noninteractive

# Upgrade to latest packages
RUN apt update && apt -y upgrade

# Set environment variables
RUN echo debconf debconf/frontend select Noninteractive | debconf-set-selections
RUN echo tzdata tzdata/Areas select ${TIMEZONE_AREA} | debconf-set-selections
RUN echo tzdata tzdata/Zones/Europe select ${TIMEZONE_CITY} | debconf-set-selections

# Install languages
RUN apt -y install language-pack-sv

RUN apt-get install -y software-properties-common apt-transport-https \
cron nano monit wget unzip curl less nginx;
# /usr/bin/unattended-upgrades -v;

# RUN apt-get install -y nginx;

#php-base
RUN add-apt-repository -y ppa:ondrej/php; \
# export DEBIAN_FRONTEND=noninteractive; \
apt-get install -yq php${PHP_VERSION} php${PHP_VERSION}-cli \
php${PHP_VERSION}-common php${PHP_VERSION}-curl php${PHP_VERSION}-fpm php${PHP_VERSION}-json \
php${PHP_VERSION}-mysql php${PHP_VERSION}-readline \
php${PHP_VERSION}-xml php${PHP_VERSION}-xsl php${PHP_VERSION}-gd php${PHP_VERSION}-intl \
php${PHP_VERSION}-bz2 php${PHP_VERSION}-bcmath php${PHP_VERSION}-gd \
php${PHP_VERSION}-mbstring php${PHP_VERSION}-xmlrpc php${PHP_VERSION}-zip ;

#oh maria!
RUN apt-get install -yq mariadb-server mariadb-client; \
cd /usr/share && ( \
  wget -q https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN}/phpMyAdmin-${PHPMYADMIN}-all-languages.zip; \
  unzip -oq phpMyAdmin-${PHPMYADMIN}-all-languages.zip; \
  mv phpMyAdmin-${PHPMYADMIN}-all-languages pma; \
  rm -f phpMyAdmin-${PHPMYADMIN}-all-languages.zip; \
);

#let`s compose!
# RUN mkdir /opt/composer; \
# cd /opt/composer && ( \
#     wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q | php -- --quiet; \
#     ln -s /opt/composer/composer.phar /usr/local/bin/composer; \
# )

COPY ./conf/ssmtp.conf.template /etc/ssmtp/
COPY ./monit/monitrc /etc/monit/
COPY ./monit/cron ./monit/php-fpm ./monit/nginx /etc/monit/conf-enabled/
COPY ./php/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/
COPY ./php/php-fpm.conf ./php/php.ini ./conf/env.conf /etc/php/${PHP_VERSION}/fpm/
COPY ./nginx/default /etc/nginx/sites-enabled/default
COPY ./phpmyadmin/config.inc.php /usr/share/pma/config.inc.php

ENTRYPOINT ["/docker-entrypoint.sh"]
