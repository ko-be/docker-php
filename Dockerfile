FROM ubuntu:14.04.2
MAINTAINER Bryan Latten <latten@adobe.com>

# Define the location where downstream app should live, with a child public folder
ENV HTTP_WEBROOT /app/public

# Install pre-reqs, security updates
RUN apt-get update && \
    apt-get -yq install \
        openssl=1.0.1f-1ubuntu2.15 \
        ca-certificates=20141019ubuntu0.14.04.1 \
        wget

# Ensure package list is up to date, add tool for PPA in the next step
RUN apt-get update && \
    apt-get install software-properties-common=0.92.37.3 -y

# Install latest git with security updates
# http://article.gmane.org/gmane.linux.kernel/1853266
RUN add-apt-repository ppa:git-core/ppa -y && \
    apt-get update -yq && \
    apt-get install -yq git

# Install singularity_runner
RUN apt-get install build-essential ruby1.9.1-dev -y && \
    gem install --no-rdoc --no-ri singularity_dsl --version 1.6.3


# Install latest nginx-stable
RUN add-apt-repository ppa:nginx/stable -y && \
    apt-get update -yq && \
    apt-get install -yq nginx=1.8.0-1+trusty1

# IMPORTANT: PPA has UTF-8 characters in it that will fail unless locale is generated
RUN locale-gen en_US.UTF-8 && export LANG=en_US.UTF-8 && add-apt-repository ppa:ondrej/php-7.0 -y

# Update package cache with new PPA, install language and modules
RUN apt-get update && \
    apt-get -yq install \
        php7.0-common \
        php7.0-cli \
        php7.0-fpm \
        php7.0-curl \
        php7.0-gd \
        php7.0-dev \
        #php7.0-json \  Still broken on beta

        # php5-gearman=1.1.2-1+deb.sury.org~trusty+2 \
        # php5-memcache=3.0.8-5+deb.sury.org~trusty+1 \
        # php5-memcached=2.2.0-2+deb.sury.org~trusty+1 \
        # php5-dev \
        # php5-gd \
        # php5-mysqlnd \
        # php5-mcrypt \
        # php5-xdebug \
        nano

# RUN pecl install igbinary-1.2.1 && \
#     echo 'extension=igbinary.so' > /etc/php5/mods-available/igbinary.ini && \
#     php5enmod igbinary

# RUN printf "\n" | pecl install apcu-4.0.7 && \
#     echo 'extension=apcu.so' > /etc/php5/mods-available/apcu.ini && \
#     php5enmod apcu


# Perform cleanup, ensure unnecessary packages are removed
RUN apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /tmp/* /var/tmp/* && \
    rm -rf /var/lib/apt/lists/*

# Overlay the root filesystem from this repo
COPY ./container/root /

#####################################################################

# Move downstream application to final resting place
ONBUILD COPY ./ /app/

#####################################################################


# Packages in this parent container are provided for ease of integration
# in downstream (child) builds. Some dev-only packages need to be removed
# for a production system (git/wget/gcc/etc)

# TODO: script needs to be called AFTER downstream build is performed,
#   ONBUILD instruction gets called BEFORE, so not useful
# RUN /bin/bash /clean.sh



EXPOSE 80
CMD ["/bin/bash", "/run.sh"]
