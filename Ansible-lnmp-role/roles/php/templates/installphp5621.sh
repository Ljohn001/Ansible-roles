## VARIABLE SETTING
PHPDIR=/usr/local/php
CONFDIR=$PHPDIR/etc
MYSQLDIR=/usr/local/mysql
MYSQLSOCK=/tmp/mysql.sock

## USER CREATE
useradd -r -s /sbin/nologin php-fpm

## BASE PACKAGE INSTALLATION
yum install gcc gcc-c++ cmake ncurses-devel epel-release -y
yum groupinstall base "Development Tools" -y
yum install libxml2-devel libcurl-devel libjpeg-turbo-devel libpng-devel freetype-devel php-mcrypt libmcrypt-devel libevent-devel -y

## LIB PREPARE
ln -s /usr/lib64/libjpeg.so /usr/lib/libjpeg.so 
ln -s /usr/lib64/libpng.so /usr/lib/libpng.so

## TARBALL INSTALL PHP
tar zxvf php-5.6.21.tar.gz
cd php-5.6.21
./configure --prefix=$PHPDIR --with-config-file-path=$CONFDIR --enable-fpm --with-fpm-user=php-fpm --with-fpm-group=php-fpm --with-mysql=$MYSQLDIR --with-mysql-sock=$MYSQLSOCK --with-libxml-dir  --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --with-iconv-dir --with-zlib-dir --with-mcrypt --enable-soap --enable-gd-native-ttf --enable-ftp --enable-mbstring --enable-exif --disable-ipv6 --with-curl --with-openssl
make
make install

## INI FILE AND DAEMON FILE PREPARE
mkdir $CONFDIR
cp php.ini-production $CONFDIR/php.ini
cp $CONFDIR/php-fpm.conf.default $CONFDIR/php-fpm.conf
cp ./sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod 755 /etc/init.d/php-fpm

sed -i 's/.*pm.max_children =.*/pm.max_children = 50/g' $CONFDIR/php-fpm.conf
sed -inr 's/.*pm.start_servers =.*/pm.start_servers = 20/g' $CONFDIR/php-fpm.conf
sed -inr 's/.*pm.min_spare_servers =.*/pm.min_spare_servers = 5/g' $CONFDIR/php-fpm.conf
sed -inr 's/.*pm.max_spare_servers =.*/pm.max_spare_servers = 35/g' $CONFDIR/php-fpm.conf
sed -inr "s#.*pid.*php-fpm.pid.*#pid = $PHPDIR/var/run/php-fpm.pid#g" $CONFDIR/php-fpm.conf


## SERVICE ENABLE AND START
chkconfig --add php-fpm
chkconfig php-fpm on
