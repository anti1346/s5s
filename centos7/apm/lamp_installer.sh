#!/bin/bash

DOWNLOAD_URL='http://192.168.100.101:8181'   # Download URL
SOURCE_DIR='/usr/local/src'                  # Source directory
TARGET_DIR='/app/apm'                        # Target directory

function display_output(){
    local software_name=$1
    echo -e "+++++++++++++++++++++++++++++++++++++++++++"
    curl -s ${DOWNLOAD_URL}/app_list.txt | egrep "${software_name}"
    echo -e "+++++++++++++++++++++++++++++++++++++++++++\n"
}

function library_install(){
    yum install -y gcc make cmake gcc-c++
    yum install -y zlib-devel openssl-devel apr-devel pcre-devel expat-devel ncurses-devel
    yum install -y libxml2-devel curl-devel gd-devel
}

function apache_install(){
    display_output "http"
    read -p "Apache version [default: 2.4.29]: " apache_version
    apache_version=${apache_version:=2.4.29}
    
    read -p "APR version [default: 1.6.5]: " apr_version
    apr_version=${apr_version:=1.6.5}
    
    read -p "APR-util version [default: 1.6.1]: " apr_util_version
    apr_util_version=${apr_util_version:=1.6.1}

    wget -c ${DOWNLOAD_URL}/httpd-${apache_version}.tar.gz -O - | tar -xz -C ${SOURCE_DIR}
    cd ${SOURCE_DIR}/httpd-${apache_version}
    
    # 서버 기본 설정 변경
    sed -i 's/DEFAULT_SERVER_LIMIT 16/DEFAULT_SERVER_LIMIT 128/g' server/mpm/worker/worker.c

    cd ${SOURCE_DIR}/httpd-${apache_version}/srclib
    wget -c ${DOWNLOAD_URL}/apr-${apr_version}.tar.gz -O - | tar -xz -C ${SOURCE_DIR}/httpd-${apache_version}/srclib
    mv apr-${apr_version} apr

    wget -c ${DOWNLOAD_URL}/apr-util-${apr_util_version}.tar.gz -O - | tar -xz -C ${SOURCE_DIR}/httpd-${apache_version}/srclib
    mv apr-util-${apr_util_version} apr-util

    cd ${SOURCE_DIR}/httpd-${apache_version}

    ./configure \
    --prefix=${TARGET_DIR}/apache2 \
    --enable-so \
    --enable-rewrite \
    --enable-modules=most \
    --enable-mods-shared=all \
    --enable-ssl \
    --enable-nonportable-atomics=yes \
    --with-included-apr \
    --with-ssl \
    --with-mpm=worker

    make -j$(nproc)
    make install
}

function mysql_install(){
    display_output "mysql"
    
    read -p "MySQL version [default: 5.7.29]: " mysql_version
    mysql_version=${mysql_version:=5.7.29}
    
    read -p "Boost version [default: 1.59.0]: " boost_version
    boost_version=${boost_version:=1.59.0}

    wget -c ${DOWNLOAD_URL}/boost-${boost_version}.tar.gz -O - | tar -xz -C ${SOURCE_DIR}
    wget -c ${DOWNLOAD_URL}/mysql-${mysql_version}.tar.gz -O - | tar -xz -C ${SOURCE_DIR}
    
    cd ${SOURCE_DIR}/mysql-${mysql_version}
    
    cmake \
    -DCMAKE_INSTALL_PREFIX=${TARGET_DIR}/mysql \
    -DSYSCONFDIR=${TARGET_DIR}/etc \
    -DMYSQL_DATADIR=${TARGET_DIR}/data \
    -DMYSQL_UNIX_ADDR=${TARGET_DIR}/tmp/mysql.sock \
    -DMYSQL_TCP_PORT=3306 \
    -DENABLED_LOCAL_INFILE=1 \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=../boost-${boost_version} \
    -DDEFAULT_CHARSET=utf8 \
    -DWITH_EXTRA_CHARSETS=all \
    -DDEFAULT_COLLATION=utf8_general_ci
    
    make -j$(nproc)
    make install
}

function php_install(){
    display_output "php"
    
    read -p "PHP version [default: 7.3.11]: " php_version
    php_version=${php_version:=7.3.11}

    wget -c ${DOWNLOAD_URL}/php-${php_version}.tar.gz -O - | tar -xz -C ${SOURCE_DIR}
    cd ${SOURCE_DIR}/php-${php_version}
    
    ./configure \
    --prefix=${TARGET_DIR}/php \
    --with-apxs2=${TARGET_DIR}/apache2/bin/apxs \
    --with-config-file-path=${TARGET_DIR}/apache2/conf \
    --enable-sockets \
    --with-mysqli \
    --enable-opcache=no \
    --with-zlib \
    --enable-ftp \
    --enable-debug \
    --enable-shmop \
    --with-gd \
    --with-freetype-dir \
    --with-zlib \
    --with-iconv \
    --with-jpeg-dir=/usr/lib \
    --with-libxml-dir \
    --without-pear \
    --enable-mbstring \
    --with-curl \
    --with-openssl \
    --with-imap-ssl \
    --enable-sigchild \
    --with-libdir=/usr/lib64

    make -j$(nproc)
    make install
}

function mysql_additional(){
    groupadd -g 27 mysql
    useradd -M -g mysql -d ${TARGET_DIR}/mysql -s /bin/false -c "MySQL Server" -u 27 mysql

    mkdir -p ${TARGET_DIR}/mysql/tmp
    mkdir -p ${TARGET_DIR}/mysql/logs

    chown -R mysql:mysql ${TARGET_DIR}/mysql
    chown mysql:mysql ${TARGET_DIR}/mysql/tmp

    ${TARGET_DIR}/mysql/bin/mysqld --initialize \
    --defaults-file=${TARGET_DIR}/mysql/etc/my.cnf \
    --user=mysql \
    --basedir=${TARGET_DIR}/mysql/ \
    --datadir=${TARGET_DIR}/mysql/data
}

function php_additional(){
    cp ${SOURCE_DIR}/php-${php_version}/php.ini-development ${TARGET_DIR}/apache2/conf/php.ini

    echo "<?php phpinfo() ?>" > ${TARGET_DIR}/apache2/htdocs/phpinfo.php

    echo "AddType application/x-httpd-php .php .html" >> ${TARGET_DIR}/apache2/conf/httpd.conf
    echo "AddType application/x-httpd-php-source .phps" >> ${TARGET_DIR}/apache2/conf/httpd.conf
}

## Main
library_install
apache_install
mysql_install
php_install
mysql_additional
php_additional
