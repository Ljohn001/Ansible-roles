set -e
## VARIABLE SETTING
PHPDIR={{ php_base_dir }}
CONFDIR={{ php_conf_dir }}
MYSQLDIR={{ mysql_base_dir }}
MYSQLSOCK={{ mysql_socket }}
VERSION={{ php.version }}
DAEMON_USER={{ php_daemon_user }}
DAEMON_NAME={{ php_daemon_name }}


## LIB PREPARE
[ -e "/usr/lib/libjpeg.so" ] || ln -s /usr/lib64/libjpeg.so /usr/lib/libjpeg.so
[ -e "/usr/lib/libpng.so" ] || ln -s /usr/lib64/libpng.so /usr/lib/libpng.so

## TARBALL INSTALL PHP
[[ -d php-$VERSION ]] && rm -rf php-$VERSION
tar zxf php-${VERSION}.tar.gz
cd php-${VERSION}
./configure {{ php.configure_args }}
make
make install

## INI FILE AND DAEMON FILE PREPARE
mkdir -p $CONFDIR
cp php.ini-production $CONFDIR/php.ini
cp $CONFDIR/php-fpm.conf.default $CONFDIR/php-fpm.conf
cp ./sapi/fpm/init.d.php-fpm /etc/init.d/${DAEMON_NAME}
chmod 755 /etc/init.d/${DAEMON_NAME}

sed -i 's/.*pm.max_children =.*/pm.max_children = 50/g' $CONFDIR/php-fpm.conf
sed -i 's/.*pm.start_servers =.*/pm.start_servers = 20/g' $CONFDIR/php-fpm.conf
sed -i 's/.*pm.min_spare_servers =.*/pm.min_spare_servers = 5/g' $CONFDIR/php-fpm.conf
sed -i 's/.*pm.max_spare_servers =.*/pm.max_spare_servers = 35/g' $CONFDIR/php-fpm.conf
sed -i "s#.*pid.*php-fpm.pid.*#pid = $PHPDIR/var/run/php-fpm.pid#g" $CONFDIR/php-fpm.conf


## SERVICE ENABLE AND START
chkconfig --add $DAEMON_NAME
chkconfig $DAEMON_NAME on
