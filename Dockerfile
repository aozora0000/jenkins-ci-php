FROM centos:centos6
MAINTAINER Kohei Kinoshita <aozora0000@gmail.com>

# EPEL/REMIインストール
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
RUN yum -y update
RUN yum -y install ansible
RUN yum -y update gmp

# ansible provisioning
ADD ./playbook.yml /tmp/ansible/
WORKDIR /tmp/ansible
RUN ansible-playbook playbook.yml
RUN chmod 777 /etc/profile.d
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && \
    chmod a+x /usr/local/bin/composer && \
    wget https://phar.phpunit.de/phpunit.phar && mv phpunit.phar /usr/local/bin/phpunit && \
    chmod a+x /usr/local/bin/phpunit && \
    wget https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar && mv phpcs.phar /usr/local/bin/phpcs && \
    chmod a+x /usr/local/bin/phpcs

# php install
USER worker
WORKDIR /home/worker
RUN phpbrew init
RUN source /home/worker/.phpbrew/bashrc
RUN echo "source /home/worker/.phpbrew/bashrc" > /home/worker/.bashrc

# 5.6.3
RUN phpbrew install 5.6.3 && \
    source /home/worker/.phpbrew/bashrc && \
    phpbrew switch 5.6.3  && \
    phpbrew ext install curl && \
    phpbrew ext disable curl && \
    phpbrew ext enable curl && \
    phpbrew ext install xdebug && \
    phpbrew ext install opcache && \
    phpbrew ext

RUN ls /home/worker/.phpbrew/php/php-*/etc/php.ini  | xargs sed -i "s/\;date\.timezone\ \=/date\.timezone\ \=\ Asia\/Tokyo/g"

#################################
# default behavior is to login by worker user
#################################
CMD ["su", "-", "worker"]
