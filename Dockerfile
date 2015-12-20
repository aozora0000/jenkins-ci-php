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

RUN php -v

# php install
USER worker
WORKDIR /home/worker

RUN phpbrew init
RUN source /home/worker/.phpbrew/bashrc
RUN echo "source /home/worker/.phpbrew/bashrc" > /home/worker/.bashrc

# PHPインストール
RUN export PHP_VERSION=5.4.45 && \
    source /home/worker/.bashrc && \
    phpbrew install -j $(nproc) $PHP_VERSION +default +mysql +pdo +openssl=/usr -- --with-libdir=lib64 && \
    source /home/worker/.bashrc && \
    phpbrew switch $PHP_VERSION  && \
    phpbrew ext install iconv && \
    phpbrew ext install xdebug && \
    phpbrew ext install gd && \
    phpbrew ext install imagick && \
    phpbrew ext install tidy

RUN ls /home/worker/.phpbrew/php/php-*/etc/php.ini | xargs sed -i "s/\;date\.timezone\ \=/date\.timezone\ \=\ Asia\/Tokyo/g"
RUN ls /home/worker/.phpbrew/php/php-*/etc/php.ini | xargs sed -i "s/\;phar.readonly.*/phar.readonly = Off/g"

#################################
# default behavior is to login by worker user
#################################
CMD ["su", "-", "worker"]
