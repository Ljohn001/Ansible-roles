[TOC]
### 一、架构描述与应用架构
#### 1. 应用场景
    大多数的互联网公司都会利用nginx的7层反向代理功能来实现后端web server的负载均衡和动静分离。这样做的好处是当单台后端server出现性能瓶颈时可以对其进行横向扩展从而提高整个系统的并发，同时也可以通过后端server提供的http或tcp监控接口对其进行健康检查实现自动Failover和Failback。
    在nginx给我们带来诸多好处的同时，自身却成为了整套系统的单点所在，试想一下nginx如果宕机了（虽然可能性不大），整个系统将会无法访问，由此可见对nginx server进行高可用的必要性。常见的高可用解决方案有heartbeat、keepalived等，其中以keepalived的实现最为轻量级、配置简单，所以在对nginx的高可用实现中更多会采用keepalived，下面主要也是以keepalived为例讲解。
#### 2. 架构


 
### 二、环境和配置
#### 1.环境
系统使用CentSO6.9 or CentOS7.3
服务角色	IP地址	软件版本
proxy1 master	192.168.0.56	1.10.3
proxy2 backup
192.168.0.57
1.10.3
keepalived1	192.168.0.56
1.3.5
keepalived2
192.168.0.57
1.3.5
#### 2. 配置说明：
keepalived1:
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
    state MASTER
    interface ens33
    virtual_router_id 51
    priority 100  #备用机器的keepalived的权重要小于这个权重，并且当nginx服务挂掉后100-2要小于备用机器的权重。
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
    notify_master "/etc/keepalived/notify.sh master"
    notify_backup "/etc/keepalived/notify.sh backup"
    notify_fault "/etc/keepalived/notify.sh fault"
}
vrrp_instance VI_2 {
    state BACKUP
    interface ens33
    virtual_router_id 52
    priority 99  #备用机器的keepalived的权重要小于这个权重，并且当nginx服务挂掉后100-2要小于备用机器的权重。
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.0.101/16 dev ens33 label ens33:2
    }
    track_script {    #定义使用哪个脚本来检查。
        chk_nginx
   }
    notify_master "/etc/keepalived/notify.sh master"
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
    notify_master "/etc/keepalived/notify.sh master"
    notify_backup "/etc/keepalived/notify.sh backup"
    notify_fault "/etc/keepalived/notify.sh fault"
}
vrrp_instance VI_2 {
    state MASTER
    interface ens33
    virtual_router_id 52
    priority 100  #备用机器的keepalived的权重要小于这个权重，并且当nginx服务挂掉后100-2要小于备用机器的权重。
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
       192.168.0.101/16 dev ens33 label ens33:2
    }
    track_script {    #定义使用哪个脚本来检查。
        chk_nginx
    }
    notify_master "/etc/keepalived/notify.sh master"
    notify_backup "/etc/keepalived/notify.sh backup"
    notify_fault "/etc/keepalived/notify.sh fault"
}
```
监控及通知脚本：
#cat /etc/keepalived/notify.sh
```
#!/bin/bash
#
vip=192.168.0.100
contact='root@localhost'

notify() {
        mailsubject="`hostname` to be $1: vip floating"
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
#/etc/keepalived/chk_nginx.sh

#!/bin/bash
#
N=`ps -C nginx --no-header|wc -l`
if [ $N -eq 0 ];then
        /usr/local/nginx/sbin/nginx
        sleep 1
        if [ `ps -C nginx --no-header|wc -l` -eq 0 ];then
                killall nginx
        fi
fi
```

### 三、ansible deploy
###1. ansible目录结构：
```
tree .
.
├── ansible.cfg
├── site.yml
├── hosts
├── README.md
└── roles
    ├── keepalived
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   ├── templates
    │   │   ├── chk_nginx.sh
    │   │   ├── keepalived.conf.j2
    │   │   └── notify.sh
    │   └── vars
    │       └── main.yml
    └── nginx
        ├── handlers
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        ├── templates
        │   ├── nginx.conf.j2
        │   ├── nginx.init
        │   └── nginx.systemd
        └── vars
            └── main.yml

11 directories, 16 files
```
####2.执行playbook
```
# ansible-playbook site.yml 
PLAY [nginx] *******************************************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [nginx : install denpendency package] *************************************************************************************************************
ok: [192.168.0.56] => (item=[u'pcre', u'openssl', u'pcre-devel', u'openssl-devel', u'zlib-devel', u'gd', u'gd-devel'])
ok: [192.168.0.57] => (item=[u'pcre', u'openssl', u'pcre-devel', u'openssl-devel', u'zlib-devel', u'gd', u'gd-devel'])

TASK [nginx : create nginx pid user] *******************************************************************************************************************
ok: [192.168.0.57]
ok: [192.168.0.56]

TASK [nginx : download nginx source] *******************************************************************************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [nginx : unarchive nginx.tar.gz] ******************************************************************************************************************
 [WARNING]: Consider using unarchive module rather than running tar

changed: [192.168.0.56]
changed: [192.168.0.57]

TASK [nginx : compile and install nginx] ***************************************************************************************************************
ok: [192.168.0.56]
ok: [192.168.0.57]

TASK [nginx : copy nginx systemd script] ***************************************************************************************************************
ok: [192.168.0.57]
ok: [192.168.0.56]

TASK [nginx : copy nginx init script] ******************************************************************************************************************
skipping: [192.168.0.57]
skipping: [192.168.0.56]

PLAY RECAP *********************************************************************************************************************************************
192.168.0.56               : ok=7    changed=1    unreachable=0    failed=0   
192.168.0.57               : ok=7    changed=1    unreachable=0    failed=0
```
### 四、高可用测试
###1、停掉一台nginx



###2、停掉一台keepalived




