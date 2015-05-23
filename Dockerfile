FROM centos:centos6
MAINTAINER Kohei Kinoshita <aozora0000@gmail.com>

# EPEL/REMIインストール
RUN yum -y install yum-plugin-fastestmirror
RUN echo "include_only=.jp" >>  /etc/yum/pluginconf.d/fastestmirror.conf
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
    rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
RUN yum -y update && yum -y install ansible httpd-devel gmp-devel sudo
RUN echo "host_key_checking = False" >> /etc/ansible/ansible.cfg

# ansible provisioning
ADD ./playbook.yml /tmp/ansible/
WORKDIR /tmp/ansible
RUN ansible-playbook playbook.yml

# php install
WORKDIR /tmp

RUN export CFLAGS="-O3" && \
    git clone --depth 1 https://github.com/php/php-src.git && \
    cd php-src && \
    ./buildconf && \
    ./configure \
        --enable-mbstring \
        --enable-curl \
        --enable-gd \
        --enable-gettext \
        --enable-mcrypt \
        --enable-mysqli \
        --enable-mysqlnd \
        --enable-opcache \
        --enable-openssl \
        --enable-pdo_mysql \
        --enable-pdo_sqlite \
        --enable-phar \
        --enable-readline \
        --enable-simplexml \
        --with-openssl && \
    make -j $(nproc) && make install && make clean && \
    rm -rf /tmp/*

RUN wget https://getcomposer.org/composer.phar && \
    chmod +x composer.phar && mv composer.phar /usr/local/bin/composer && \
    wget https://phar.phpunit.de/phpunit.phar && \
    chmod +x phpunit.phar && mv phpunit.phar /usr/local/bin/phpunit

#################################
# default behavior is to login by worker user
#################################
CMD ["su", "-", "worker"]
