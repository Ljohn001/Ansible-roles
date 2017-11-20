# Ansible to install roles

这里需要给大家说明一下，由于该项目中包含安装文件，体积大所以不建议整体git clone 下载（比较耗时）

## 一、下载方法（示例）：
```
# yum install -y svn
##复制Ansible-keepalived-nginx-role的链接
https://github.com/Ljohn001/Ansible-roles/tree/master/Ansible-keepalived-nginx-role
##将链接中/tree/master 修改为/trunk，使用svn co 下载
# svn co https://github.com/Ljohn001/Ansible-roles/trunk/Ansible-keepalived-nginx-role
```
## 二、更新内容
更新内容  | 最后时间
---|---
Ansible-keepalived-nginx-role | 2017.11.21
Ansible-tomcat-role| 2017.10
zabbix-agent-2.4.5| 2017.10
zabbix-agent-3.4.1| 2017.10
jboss-standalone| 2017.10
lamp_simple_rhel7| 2017.10
tomcat-memcached-failover| 2017.10
tomcat-standalone|2017.10
ntp|2017.10

## 三、项目列表

###  1.Ansible-keepalived-nginx-role
 Keepalived+nginx高可用集群自动部署
  支持:CentOS6.9
       CentOS7.4

### 2.Ansible-tomcat-role
 tomcat8.5,java1.70
### 3.zabbix-agent-2.4.5
 支持:CentOS6.x
### 4.zabbix-agent-3.4.1
 支持:CentOS6.x
      CentOS7.x
### 5.Ansible-lnmp-role 
 实现nginx,mysql,php的多版本批量安装
### 6.jboss-standalone
  官方example
### 7.lamp_simple_rhel7
  官方example
### 8.tomcat-memcached-failover
  官方example 实现lnmt: nginx,memcache,tomcat 集群部署
### 9.tomcat-standalone
  官方example
### 10.mongodb
  官方example
### 11.ntp


欢迎大家来批评指正，联系方式

QQ：184694637

Mail: ljohnmail@foxmail.com
