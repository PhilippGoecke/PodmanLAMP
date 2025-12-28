FROM debian:trixie-slim as install

ARG DEBIAN_FRONTEND=noninteractive

#SHELL ["/bin/bash", "-c"]
RUN rm /bin/sh \
  && ln -s /bin/bash /bin/sh \
  && usermod -s /bin/bash root

# install dependencies
RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests apache2 \
  && apt install -y --no-install-recommends --no-install-suggests ca-certificates git curl \
  && apt install -y --no-install-recommends --no-install-suggests bzip2 build-essential zlib1g-dev libxml2-dev pkg-config libssl-dev libsqlite3-dev \
  && apt install -y --no-install-recommends --no-install-suggests libbz2-dev autoconf bison bash findutils libcurl4-gnutls-dev libicu-dev libjpeg-dev libmcrypt-dev libonig-dev libpng-dev libreadline-dev libtidy-dev libxslt1-dev libzip-dev \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

# Allow apache to bind to privileged ports (80/443)
RUN echo "net.ipv4.ip_unprivileged_port_start=80" >> /etc/sysctl.conf

# set apache log level to debug
RUN sed -ri 's/^\s*LogLevel\s+.*/LogLevel debug/' /etc/apache2/apache2.conf

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

# install phpmyadmin
RUN apt install -y --no-install-recommends --no-install-suggests phpmyadmin \
  && a2enconf phpmyadmin \
  && ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

WORKDIR /var/www/html

# create a phpinfo file
RUN echo "<?php phpinfo(); ?>" > info.php \
  && chown www-data:www-data info.php

# uncomment the following line to copy your application code
#COPY --chown=www-data:www-data . app

EXPOSE 80

# start apache in foreground mode and tail the logs
CMD ["/bin/bash", "-lc", "tail -F -n0 -q /var/log/apache2/*.log & exec apachectl -DFOREGROUND"]

HEALTHCHECK CMD curl -f "http://localhost:80" || exit 1
