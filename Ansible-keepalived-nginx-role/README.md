### 一、架构描述与应用架构
#### 1. 架构简介
    大多数的互联网公司都会利用nginx的7层反向代理功能来实现后端web server的负载均衡和动静分离。这样做的好处是当单台后端server出现性能瓶颈时可以对其进行横向扩展从而提高整个系统的并发，同时也可以通过后端server提供的http或tcp监控接口对其进行健康检查实现自动Failover和Failback。
    在nginx给我们带来诸多好处的同时，自身却成为了整套系统的单点所在，试想一下nginx如果宕机了（虽然可能性不大），整个系统将会无法访问，由此可见对nginx server进行高可用的必要性。常见的高可用解决方案有heartbeat、keepalived等，其中以keepalived的实现最为轻量级、配置简单，所以在对nginx的高可用实现中更多会采用keepalived，下面主要也是以keepalived为例讲解。
#### 2. 架构应用
![架构图](https://s5.51cto.com/oss/201711/13/b99635652a623d2b48bcb4da7f1fe025.jpg "Keepalived+nginx高可用架构")

 
### 二、环境及配置
#### 1.环境
系统使用CentSO6.9 or CentOS7.3

服务器 | IP地址| 软件版本
---|---|----
nginx proxy1  | 192.168.0.56| 1.10.3
nginx proxy2  | 192.168.0.57| 1.10.3
keepalived1   | 192.168.0.56| 1.3.5
keepalived2   | 192.168.0.57| 1.3.5
web1 httpd  | 192.168.0.58| 2.4.6 or 2.2.15
web2 httpd  | 192.168.0.59| 2.4.6 or 2.2.15

#### 2. 配置：
keepalived1:
```
#cat /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
   notification_email {
        root@localhost    #定义邮箱报警的邮箱地址
   }
   notification_email_from root@localhost #定义发送报警信息的
地址
   smtp_server 127.0.0.1 #定义发送邮件的邮件服务器地址
   smtp_connect_timeout 30 #定义发送邮件的超时时间
   router_id ha_nginx #全局标识
}

vrrp_script chk_nginx {    #定义检查nginx服务的脚本
        script "/etc/keepalived/chk_nginx.sh"
        interval 2 #检查的间隔时间
        weight -2 #检查失败的话权重减2
        fall 2 #检查失败2次才认为是真正的检查失败
}
vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 51
    priority 100  #备用机器的keepalived的权重要小于这个权重，
并且当nginx服务挂掉后100-2要小于备用机器的权重。
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
       192.168.0.100/16 dev ens33 label ens33:1
    }
    track_script {    #定义使用哪个脚本来检查。
        chk_nginx
    }
    notify_master "/etc/keepalived/notify.sh master"            #通知脚本
    notify_backup "/etc/keepalived/notify.sh backup"
    notify_fault "/etc/keepalived/notify.sh fault"
}
```
keepalived2:
```
#cat /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
   notification_email {  
        root@localhost    #定义邮箱报警的邮箱地址
   }
   notification_email_from root@localhost #定义发送报警信息的地址
   smtp_server 127.0.0.1 #定义发送邮件的邮件服务器地址
   smtp_connect_timeout 30 #定义发送邮件的超时时间
   router_id ha_nginx #全局标识
}

vrrp_script chk_nginx {    #定义检查nginx服务的脚本
        script "/etc/keepalived/chk_nginx.sh"
        interval 2 #检查的间隔时间
        weight -2 #检查失败的话权重减2
        fall 2 #检查失败2次才认为是真正的检查失败
}
vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 51
    priority 99  #备用机器的keepalived的权重要小于这个权重，并且当nginx服务挂掉后100-2要小于备用机器的权重。
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
       192.168.0.100/16 dev ens33 label ens33:1
    }
    track_script {    #定义使用哪个脚本来检查。
        chk_nginx
    } 
    notify_master "/etc/keepalived/notify.sh master"	    #通知脚本
    notify_backup "/etc/keepalived/notify.sh backup"
    notify_fault "/etc/keepalived/notify.sh fault"
}
```
监控及通知脚本：
```
#cat /etc/keepalived/notify.sh
#!/bin/bash
#
vip=192.168.0.100
contact='root@localhost'

notify() {
        mailsubject="`hostname` to be $1: $vip floating"
        mailbody="`date '+%F %H:%M:%S'`: vrrp transition, `hostname` changed to be $1"
        echo $mailbody | mail -s "$mailsubject" $contact
}

case "$1" in
        master)
                notify master
                exit 0
        ;;
        backup)
                notify backup
                exit 0
        ;;
        fault)
                notify fault
                exit 0
        ;;
        *)
                echo 'Usage: `basename $0` {master|backup|fault}'
                exit 1
        ;;
esac
```
```
#cat /etc/keepalived/chk_nginx.sh
#!/bin/bash
#
N=`ps -C nginx --no-header|wc -l`
if [ $N -eq 0 ];then
        /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
        sleep 1
        if [ `ps -C nginx --no-header|wc -l` -eq 0 ];then
                killall nginx
        fi
fi
```
RealServer配置
```
内核参数及VIP配置
cat setka.sh
#!/bin/bash
#
vip=192.168.0.100
netcard=`ip addr |grep inet |egrep -v "inet6|127.0.0.1" | awk '{print $NF}'`
case $1 in
start)
	echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
	echo 1 > /proc/sys/net/ipv4/conf/$netcard/arp_ignore
	echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
	echo 2 > /proc/sys/net/ipv4/conf/$netcard/arp_announce
	ifconfig lo:0 $vip broadcast $vip netmask 255.255.255.255 up
	;;
stop)
	ifconfig lo:0 down
	echo 0 > /proc/sys/net/ipv4/conf/all/arp_ignore
	echo 0 > /proc/sys/net/ipv4/conf/$netcard/arp_ignore
	echo 0 > /proc/sys/net/ipv4/conf/all/arp_announce
	echo 0 > /proc/sys/net/ipv4/conf/$netcard/arp_announce
	;;
*)
	echo "Usage: `basename $0` {start|stop}"
	exit 1
esac
```

### 三、ansible deploy
### 1. ansible目录结构：
```
├── ansible.cfg
├── hosts
├── README.md
├── roles
│   ├── httpd
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   │   ├── httpd2.2.conf.j2
│   │   │   ├── httpd2.4.conf.j2
│   │   │   └── setka.sh
│   │   └── vars
│   │       └── main.yml
│   ├── keepalived
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   │   ├── chk_nginx.sh
│   │   │   ├── keepalived.conf
│   │   │   └── notify.sh
│   │   └── vars
│   │       └── main.yml
│   └── nginx
│       ├── handlers
│       │   └── main.yml
│       ├── tasks
│       │   └── main.yml
│       ├── templates
│       │   ├── nginx.conf.j2
│       │   ├── nginx.init
│       │   └── nginx.systemd
│       └── vars
│           └── main.yml
└── site.yml

16 directories, 22 files
```
#### 2.执行playbook
```
#ansible-playbook site.yml 

PLAY [nginx] ************************************************************************************************

TASK [Gathering Facts] **************************************************************************************
ok: [192.168.0.57]
ok: [192.168.0.56]

TASK [nginx : install denpendency package] ******************************************************************
ok: [192.168.0.57] => (item=[u'pcre', u'openssl', u'pcre-devel', u'openssl-devel', u'zlib-devel', u'gd', u'gd-devel'])
ok: [192.168.0.56] => (item=[u'pcre', u'openssl', u'pcre-devel', u'openssl-devel', u'zlib-devel', u'gd', u'gd-devel'])

TASK [nginx : create nginx pid user] ************************************************************************
ok: [192.168.0.57]
ok: [192.168.0.56]

TASK [nginx : download nginx source] ************************************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [nginx : unarchive nginx.tar.gz] ***********************************************************************
 [WARNING]: Consider using unarchive module rather than running tar

changed: [192.168.0.57]
changed: [192.168.0.56]

TASK [nginx : compile and install nginx] ********************************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [nginx : copy nginx conf] ******************************************************************************
ok: [192.168.0.57]
ok: [192.168.0.56]

TASK [nginx : copy nginx systemd script] ********************************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [nginx : copy nginx init script] ***********************************************************************
skipping: [192.168.0.56]
skipping: [192.168.0.57]

PLAY [keepalived] *******************************************************************************************

TASK [Gathering Facts] **************************************************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [keepalived : install mailx] ***************************************************************************
ok: [192.168.0.57]
ok: [192.168.0.56]

TASK [keepalived : install  psmisc for use killall] *********************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [keepalived : install keepalived] **********************************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [keepalived : copy keepalived_config] ******************************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [keepalived : copy ch_scripts for keepalived] **********************************************************
ok: [192.168.0.56] => (item=notify.sh)
ok: [192.168.0.57] => (item=notify.sh)
ok: [192.168.0.56] => (item=chk_nginx.sh)
ok: [192.168.0.57] => (item=chk_nginx.sh)

PLAY [web] **************************************************************************************************

TASK [Gathering Facts] **************************************************************************************
ok: [192.168.0.59]
ok: [192.168.0.58]

TASK [httpd : install httpd package] ************************************************************************
ok: [192.168.0.59]
ok: [192.168.0.58]

TASK [httpd : copy vip and kernel conf] *********************************************************************
changed: [192.168.0.59]
changed: [192.168.0.58]

TASK [httpd : exec setka.sh] ********************************************************************************
changed: [192.168.0.59]
changed: [192.168.0.58]

TASK [httpd : install condiguration file for httpd] *********************************************************
changed: [192.168.0.59]
changed: [192.168.0.58]

TASK [httpd : install condiguration file for httpd] *********************************************************
skipping: [192.168.0.58]
skipping: [192.168.0.59]

TASK [httpd : test page of index.html] **********************************************************************
changed: [192.168.0.59]
changed: [192.168.0.58]

TASK [httpd : start httpd service] **************************************************************************
changed: [192.168.0.59]
changed: [192.168.0.58]

RUNNING HANDLER [httpd : restart httpd] *********************************************************************
changed: [192.168.0.59]
changed: [192.168.0.58]

PLAY RECAP **************************************************************************************************
192.168.0.56               : ok=14   changed=1    unreachable=0    failed=0   
192.168.0.57               : ok=14   changed=1    unreachable=0    failed=0   
192.168.0.58               : ok=8    changed=6    unreachable=0    failed=0   
192.168.0.59               : ok=8    changed=6    unreachable=0    failed=0  
```
### 四、高可用测试
启动两台proxy的 nginx,和keepalived
```
systemctl start nginx; ssh 192.168.0.57 'systemctl start nginx'
systemctl start keepalived ;ssh 192.168.0.57 'systemctl start keepalived'

```
1、停掉主节点的nginx
```
proxy1:  systemctl stop nginx;mv /usr/local/nginx/sbin/nginx{,.bak}

```
2、停掉主节点keepalived
```
keepalived1:  systemctl stop keepalived
```
3、恢复
```
mv /usr/local/nginx/sbin/nginx{.bak,};systemctl start nginx

#注意这里配置的是主从，一旦主的恢复，VIP将会强制漂至该节点。
```
#测试访问VIP
```
# for i in {1..5};do curl http://192.168.0.100;done
<h1>The page from web1</h1>
<h1>The page from web2</h1>
<h1>The page from web2</h1>
<h1>The page from web1</h1>
<h1>The page from web2</h1>
```

