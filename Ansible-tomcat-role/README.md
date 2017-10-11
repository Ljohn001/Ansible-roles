# ansible-tomcat_install-roles

# 配置包括Jre和Tomcat环境
版本为：
- apache-tomcat-8.5.4
- jre-7u80-linux-x64

# 使用方法

**使用说明**
``` bash
# 安装git
yum install git -y

#安装ansible(Fedora epel源)
yum install -y ansible

# 下载项目文件
git clone https://github.com/Ljohn001/tomcat_install.git

cd tomcat_install
# 目录结构
tree .
├── hosts
├── README.md
├── roles
│   ├── env
│   │   └── tasks
│   │       └── main.yml
│   └── tomcat_install
│       ├── files
│       │   ├── apache-tomcat-8.5.4.tar.gz
│       │   └── jre-7u80-linux-x64.tar.gz
│       ├── tasks
│       │   └── main.yml
│       ├── templates
│       │   ├── install_tomcat.sh
│       │   └── java-env-7u80.sh
│       └── vars
│           └── main.yml
└── site.yml
```

**配置**
修改hosts文件
```bash
#vim hosts
#示例:增加host到分组tomcat,java
[tomcat]
192.168.1.130
[java]
192.168.1.130

```
修改site.yml文件
```bash
vim site.yml
- hosts: tomcat
  remote_user: root

  roles:
    - env
    - tomcat_install
```

***运行***
```bash
ansible-playbook -i hosts site.yml
```

# 单独安装Java的Jre运行环境

***修改***
```bash
vim roles/tomcat_install/tasks/main.yml
# 注释最后三行
#- shell: sh ./install_tomcat.sh
#  args:
#    chdir: /usr/local/src/

```
***运行***
```bash
ansible-playbook -i hosts site.yml
```

