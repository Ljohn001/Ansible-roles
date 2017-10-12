## CONFIGUE ARGS ##
DAEMON_NAME={{ nginx_daemon_name }}
DAEMON_USER={{ nginx_daemon_user }}
BASEDIR={{ nginx_base_dir }}
WEBDIR={{ nginx_web_dir }}
LOGDIR={{ nginx_log_dir }}
VERSION={{ nginx.version }}

## TARBALL INSTALL NGINX ##
[[ -d nginx-$VERSION ]] && rm -rf nginx-$VERSION
tar zxf nginx-$VERSION.tar.gz
cd nginx-$VERSION
./configure {{ nginx.configure_args }}
make
make install

## CREATE WEB AND LOG DIR ##
mkdir -p $WEBDIR
mkdir -p $LOGDIR

## MAKE NGINX ENABLE AND START ##
service $DAEMON_NAME start
chkconfig $DAEMON_NAME on