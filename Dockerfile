FROM php:7.3.3-apache

# Instala o composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer

RUN apt-get update && apt-get upgrade -y && apt-get install --yes zip unzip

#instala as extensões do mongo
RUN pecl install mongodb && \
#docker-php-ext-enable mongodb && \
docker-php-ext-enable mongodb
#libcurl4-openssl-dev pkg-config libssl-dev

# Instala as extensões do mysql e mysqli
RUN docker-php-ext-install pdo_mysql mysqli

# Instala as extensoes do php
RUN apt-get update && \
    apt-get -y install apt-utils curl && \
    # Instala bibliotecas para xml e zip
    apt-get -y install libxml2-dev libzip-dev git

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip

# Adiciono o volume
VOLUME [ "/var/www/html" ]

# Como sei que o laravel é dentro da pasta public, altero o document root pra lá
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Habilita o Mod Rewrite do Apache 2
RUN a2enmod rewrite

RUN yes | pecl install xdebug-2.7.2 \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

    RUN sed -i "s/MaxKeepAliveRequests 100/MaxKeepAliveRequests 600/" /etc/apache2/apache2.conf \
    && sed -i "s/KeepAliveTimeout 5/KeepAliveTimeout 3/" /etc/apache2/apache2.conf

RUN chown -R www-data:www-data /var/www

USER root

COPY app.entrypoint.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/app.entrypoint.sh

WORKDIR /var/www

ENTRYPOINT ["app.entrypoint.sh"]
CMD ["apache2-foreground"]

#EXPOSE 80
