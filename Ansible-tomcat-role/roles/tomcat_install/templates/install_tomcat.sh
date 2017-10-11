#!/bin/bash

# author: zack
# date: 2016-07-30
# for auto deploy jre and tomcat

# ENV SETTING
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
basedir=`readlink -f $(dirname $0)`
# setting for user customize
jre_tar={{ tomcat85.jre7u80.jre_tar }}
jre_folder={{ tomcat85.jre7u80.jre_folder }}
tomcat_tar={{ tomcat85.tomcat_tar }}
tomcat_folder={{ tomcat85.tomcat_folder }}

jre_base=/usr/local/$jre_folder
tomcat_base=/usr/local/tomcat

# DEPLOY JRE
[ -d "${basedir}/${jre_folder}" ] && rm -rf ${basedir}/${jre_folder}
tar zxf $jre_tar
[ -d "$jre_base" ] && rm -rf $jre_base
mv ${basedir}/${jre_folder} $jre_base

# DEPLOY TOMCAT
[ -d "${basedir}/${tomcat_folder}" ] && rm -rf ${basedir}/${tomcat_folder}
tar zxf $tomcat_tar
[ -d "$tomcat_base" ] && rm -rf $tomcat_base
mv ${basedir}/${tomcat_folder} $tomcat_base
# prepare daemon script
/bin/cp ${tomcat_base}/bin/catalina.sh /etc/init.d/tomcat
sed -i "2a # chkconfig: 2345 63 37" /etc/init.d/tomcat
sed -i "3a . /etc/init.d/functions" /etc/init.d/tomcat
sed -i "4a JAVA_HOME=${jre_base}" /etc/init.d/tomcat
sed -i "5a CATALINA_HOME=${tomcat_base}" /etc/init.d/tomcat
chmod 755 /etc/init.d/tomcat
