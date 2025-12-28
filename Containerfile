FROM debian:trixie-slim as install

ARG DEBIAN_FRONTEND=noninteractive

#SHELL ["/bin/bash", "-c"]
RUN rm /bin/sh \
  && ln -s /bin/bash /bin/sh

# install dependencies
RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests apache2 php php-mysql libapache2-mod-php \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

# Allow apache to bind to privileged ports (80/443)
RUN echo "net.ipv4.ip_unprivileged_port_start=80" >> /etc/sysctl.conf

# set apache log level to debug
RUN sed -ri 's/^\s*LogLevel\s+.*/LogLevel debug/' /etc/apache2/apache2.conf

# install phpmyadmin
RUN apt install -y --no-install-recommends --no-install-suggests phpmyadmin \
  && ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives \
  && cp /usr/share/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php \
  && sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg\['blowfish_secret'\] = '"$(php -r 'echo bin2hex(random_bytes(32));')"';/" /var/www/html/phpmyadmin/config.inc.php \
  && sed -i "s/\$cfg\['Servers'\]\[\$i\]\['auth_type'\] = 'cookie';/\$cfg\['Servers'\]\[\$i\]\['auth_type'\] = 'config';/" /var/www/html/phpmyadmin/config.inc.php \
  && sed -i "s/\$cfg\['Servers'\]\[\$i\]\['host'\] = 'localhost';/\$cfg\['Servers'\]\[\$i\]\['host'\] = 'host.containers.internal';\n\$cfg\['Servers'\]\[\$i\]\['user'\] = getenv('PMA_USER') ?: 'root';\n\$cfg\['Servers'\]\[\$i\]\['password'\] = getenv('PMA_PASSWORD') ?: 'secret';/" /var/www/html/phpmyadmin/config.inc.php

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
