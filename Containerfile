FROM debian:trixie-slim as install

ARG DEBIAN_FRONTEND=noninteractive

#SHELL ["/bin/bash", "-c"]
RUN rm /bin/sh \
  && ln -s /bin/bash /bin/sh

# install dependencies
RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests apache2 libapache2-mod-php \
  #&& apt install -y --no-install-recommends --no-install-suggests php php-mysql libapache2-mod-php \
  && apt install -y --no-install-recommends --no-install-suggests ca-certificates git \
  && apt install -y --no-install-recommends --no-install-suggests curl bzip2 gcc build-essential zlib1g-dev libxml2-dev pkg-config libssl-dev libsqlite3-dev \
  && apt install -y --no-install-recommends --no-install-suggests libbz2-dev autoconf bison bash findutils libcurl4-gnutls-dev libicu-dev libjpeg-dev libmcrypt-dev libonig-dev libpng-dev libreadline-dev libtidy-dev libxslt1-dev libzip-dev \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

# Allow apache to bind to privileged ports (80/443)
RUN echo "net.ipv4.ip_unprivileged_port_start=80" >> /etc/sysctl.conf

# set apache log level to debug
RUN sed -ri 's/^\s*LogLevel\s+.*/LogLevel debug/' /etc/apache2/apache2.conf

# add user and set home directory
ARG USER=phpuser
RUN useradd --create-home --shell /bin/bash $USER
ARG HOME="/home/$USER"
WORKDIR $HOME
#USER $USER

# install PHP using phpenv
ENV PATH="$HOME/.phpenv/bin:$PATH"
RUN git clone --depth 1 https://github.com/phpenv/phpenv.git ~/.phpenv \
  && ~/.phpenv/bin/phpenv init - \
  && which phpenv \
  && phpenv --version \
  && mkdir "$(phpenv root)"/plugins/ \
  && git clone --depth 1 https://github.com/php-build/php-build.git "$(phpenv root)"/plugins/php-build \
  && phpenv rehash \
  && phpenv install 8.4.15 \
  && phpenv global 8.4.15
ENV PATH="$HOME/.phpenv/shims:$PATH"

WORKDIR /var/www/html

RUN echo "<?php phpinfo(); ?>" > info.php \
  && chown www-data:www-data info.php

##COPY --chown=<user>:<group> <hostPath> <containerPath>
#COPY --chown=www-data:www-data . app

EXPOSE 80

CMD apachectl -DFOREGROUND

HEALTHCHECK CMD curl -f "http://localhost:80" || exit 1
