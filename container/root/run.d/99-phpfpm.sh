#!/bin/bash

PHPFPM_CONF=/etc/php5/fpm/pool.d/www.conf

if [[ $CONTAINER_ROLE != 'web' ]]
then
  echo '[php-fpm] non-web mode, bypassing run sequence'
  exit
fi

echo '[php-fpm] setting sensible PHP defaults'
php5enmod defaults

# Baseline "optimizations" before ApacheBench succeeded at concurrency of 150
# TODO: base on current memory capacity + CPU cores
sed -i "s/pm.max_children = [0-9]\+/pm.max_children = 48/" $PHPFPM_CONF
sed -i "s/pm.start_servers = [0-9]\+/pm.start_servers = 16/" $PHPFPM_CONF
sed -i "s/pm.min_spare_servers = [0-9]\+/pm.min_spare_servers = 4/" $PHPFPM_CONF
sed -i "s/pm.max_spare_servers = [0-9]\+/pm.max_spare_servers = 32/" $PHPFPM_CONF

# php5-fpm processes must pick up stdout/stderr from workers, will cause minor performance decrease (but is required)
sed -i "s/;catch_workers_output/catch_workers_output/" $PHPFPM_CONF


# 1. runs php5-fpm as foreground (-F)
# 2. forcing php5-fpm to log to stderr even if a non-terminal is attached (-O)
# 3. redirect stderr to stdout
# 4. filtering the garbage string that PHP-FPM for no-reason-at-all decided to wrap the message in,
# 5. reconnecting the stdout to current stdout
# 6. backgrounding that process
echo '[php-fpm] starting (background)'
php-fpm7.0 -F -O 2>&1 | sed -u 's,.*: \"\(.*\)$,\1,'| sed -u 's,"$,,' 1>&1 &
