FROM centos:centos6
MAINTAINER Kohei Kinoshita <aozora0000@gmail.com>

# EPEL/REMIインストール
RUN yum -y install yum-plugin-fastestmirror
RUN echo "include_only=.jp" >>  /etc/yum/pluginconf.d/fastestmirror.conf
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
    rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
RUN yum -y update && yum -y install ansible httpd-devel gmp-devel
RUN echo "host_key_checking = False" >> /etc/ansible/ansible.cfg

# ansible provisioning
ADD ./playbook.yml /tmp/ansible/
WORKDIR /tmp/ansible
RUN ansible-playbook playbook.yml
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && \
    chmod 777 /usr/local/bin/composer && \
    wget -q https://phar.phpunit.de/phpunit.phar && mv phpunit.phar /usr/local/bin/phpunit && \
    chmod 777 /usr/local/bin/phpunit && \
    wget -q https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar && mv phpcs.phar /usr/local/bin/phpcs && \
    chmod 777 /usr/local/bin/phpcs && \
    curl -o /usr/local/bin/phing http://www.phing.info/get/phing-latest.phar && chmod a+x /usr/local/bin/phing

# php install
USER worker
WORKDIR /home/worker
RUN phpbrew init
RUN source /home/worker/.phpbrew/bashrc
RUN echo "source /home/worker/.phpbrew/bashrc" > /home/worker/.bashrc

# 5.6.4
RUN phpbrew install 5.6.4 && \
    source /home/worker/.phpbrew/bashrc && \
    phpbrew switch 5.6.4  && \
    phpbrew ext install iconv && \
    phpbrew ext install xdebug && \
    phpbrew ext install opcache && \
    phpbrew ext install pdo_mysql && \
    phpbrew ext

RUN ls /home/worker/.phpbrew/php/php-*/etc/php.ini | xargs sed -i "s/\;date\.timezone\ \=/date\.timezone\ \=\ Asia\/Tokyo/g"
RUN ls /home/worker/.phpbrew/php/php-*/etc/php.ini | xargs sed -i "s/\;phar.readonly.*/phar.readonly = Off/g"

#################################
# default behavior is to login by worker user
#################################
CMD ["su", "-", "worker"]
