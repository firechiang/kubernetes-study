#### 一、编译安装用户配置文件生成工具Httpd，[官方编译安装文档](http://httpd.apache.org/docs/2.4/install.html)
```bash
$ wget -P /home/chiangfire/data-dev/httpd/httpd-2.4.46-source https://mirrors.bfsu.edu.cn/apache//httpd/httpd-2.4.46.tar.gz
$ mkdir /home/chiangfire/data-dev/httpd/httpd && cd /home/chiangfire/data-dev/httpd/httpd-2.4.46-source
# 检查编译并配置指定安装目录（注意：这个工具编译需要 apr 和 apr-util 工具，如果电脑上没有需要安装）
$ ./configure --prefix=/home/chiangfire/data-dev/httpd/httpd
# 编译
$ make
# 编译安装
$ make install
```
#### 二、生成用户配置文件
```bash
# 定位到生成用户配置文件工具目录
$ cd /home/chiangfire/data-dev/httpd/httpd-2.4.46/bin
# 生成新的用户配置文件 htpasswd_users 并在里面添加用户：jiang 密码：123456
# 注意：-b表示添加用户，-c表示生成配置文件
$ ./htpasswd -bc /home/chiangfire/data-dev/nginx/users/htpasswd_users jiang 123456
# 往用户配置文件里面添加新的用户：tiantian 密码：123456
$ ./htpasswd -b /home/chiangfire/data-dev/nginx/users/htpasswd_users tiantian 123456
```

#### 三、配置用户访问的配置示列
```bash
http {
    server {
        # 注意：下面的配置可以配置在server或http段
        location / {
            # 提示输入用户名密码弹出框的说明信息
            auth_basic "请输入用户名密码";
            # 用户配置文件（注意：用户配置文件我们在上面已经生成好了）
            auth_basic_user_file /home/chiangfire/data-dev/nginx/users/htpasswd_users;
        }
    }
}
```
