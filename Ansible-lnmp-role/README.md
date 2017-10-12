## ansible-lnmp 简介
目标:实现nginx,mysql,php的多版本一键安装

特性:
- 实现单文件中集中配置变量
- nginx,mysql,php使用不同role组织

## 配置文件
group_vars目录中的all文件中集中了所有配置

## 使用方法
**安装ansible**
[ansible安装及基础知识](http://blog.xiao5tech.com/2016/07/26/026-devops_ansible_tutorial/)

**使用说明**
``` bash
# 安装git
yum install git -y

# 下载项目文件
git clone https://github.com/xiaotuanyu120/ansible-lnmp.git
cd ansible-lnmp

# 配置
修改hosts文件,编辑host信息
``` bash
# 示例:增加host到分组web
[web]
192.168.1.106
```

修改项目根目录下的main.yml,来确定mysql,nginx,php的版本
``` bash
# 示例:安装mysql5.5.49版本和nginx1.8.0版本，nginx180配置来自于group_vars/all文件
---
- hosts: lnmp
  remote_user: root

  roles:
    - {role: env}
    # - {role: mysql, mysql: "{{ mysql5549 }}"}
    - {role: nginx, nginx: "{{ nginx180 }}"}
```

如有必要,修改group_vars/all文件来修改各软件相应的配置项
``` bash
# 示例:nginx1.8.0版本的相关配置
nginx180:
  version: 1.8.0
  configure_args: >
    --user=$DAEMON_USER --group=$DAEMON_USER --prefix=$BASEDIR --with-http_stub_status_module --with-http_ssl_module --with-pcre --with-http_realip_module

nginx_base_dir: /usr/local/nginx
nginx_web_dir: /data/web/www 
nginx_log_dir: /data/web/log
nginx_daemon_name: nginxd
nginx_daemon_user: nginx
```


# 执行安装
ansible-playbook -i hosts main.yml
```
