#### 一、环境准备关闭 [vi /etc/sysconfig/selinux]  系统SELINUX（注意：生产环境不建议关闭SELINUX，配置生效需要重启机器）
```bash
SELINUX=disabled

# 重启系统以生效关闭SELINUX配置
$ reboot
```

#### 二、下载以及安装，[官方搭建文档](https://docs.gitlab.com/omnibus/installation/)
```bash
$ mkdir -p /home/gitlab && cd /home/gitlab

# 安装Gitlab依赖组件（注意：postfix 是邮件组件）
$ yum -y install curl policycoreutils openssh-server openssh-clients postfix

# 下载适用于Centos7的Gitlab安装包
$ wget https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/gitlab-ce-13.9.3-ce.0.el7.x86_64.rpm

# 安装Gitlab
$ rpm -Uvh gitlab-ce-13.9.3-ce.0.el7.x86_64.rpm
```

#### 三、修改 [vi /etc/gitlab/gitlab.rb] 配置
```bash
# 服务绑定的地址，可以写域名（注意：其实这个是Nginx绑定的地址，因为要访问Gitlab其实是通过Nginx做代理转发的）
external_url 'http://192.168.229.143'
# Nginx服务绑定地址（注意：因为要访问Gitlab其实是通过Nginx做代理转发的）
nginx['listen_addresses'] = ['192.168.229.143', '[::]']
# Nginx服务绑定端口（注意：因为要访问Gitlab其实是通过Nginx做代理转发的）
nginx['listen_port'] = 9199
```

#### 四、启动Gitlab以及相关服务
```bash
# 重新配置Gitlab以及相关服务，包括Nginx
# 注意：每次修改 /etc/gitlab/gitlab.rb 配置文件都需要执行该命令以生效；还有该命令执行可能需要很长时间
$ gitlab-ctl reconfigure

# 启动Gitlab以及相关服务
$ gitlab-ctl start

# 重启Gitlab以及相关服务
$ gitlab-ctl restart

# 停止Gitlab以及相关服务
$ gitlab-ctl stop
```

#### 五、首次访问Gitlab配置管理员密码，如下图（访问地址：http://192.168.229.143:9199/）
<img src="../images/index-password.png"/>


#### 二、使用Omnibus Gitlab-ce package安装Gitlab
```bash
# 安装Gitlab依赖组件
$ yum -y install curl policycoreutils openssh-server openssh-clients postfix

# 下载安装Gitlab yum源
$ curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash

# 安装Gitlab-ce（社区版）
$ yum install -y gitlab-ce
```

#### 三、创建 Gitlab 证书密钥
```bash
$ mkdir -p /home/gitlab/ssh && cd /home/gitlab/ssh

# 创建密钥key
$ openssl genrsa -out "/home/gitlab/ssh/gitlab.example.com.key" 2048

# csr创建证书
$ openssl req -new -key "/home/gitlab/ssh/gitlab.example.com.key" -out "/home/gitlab/ssh/gitlab.example.com.csr"
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
# 国家
Country Name (2 letter code) [XX]:cn
# 城市
State or Province Name (full name) []:sz
# 城市
Locality Name (eg, city) [Default City]:sz
Organization Name (eg, company) [Default Company Ltd]:
Organizational Unit Name (eg, section) []:
# 证书要绑定的域名（注意：不要写错了）
Common Name (eg, your name or your server's hostname) []:gitlab.example.com
Email Address []:firechiang@outlook.com

Please enter the following 'extra' attributes
to be sent with your certificate request
# 证书密码（注意：不要写错了）
A challenge password []:jiang123456
# 公式名称
An optional company name []:jiang

# 使用密钥key和csr创建crt证书（注意：x509是crt证书的格式，365是crt证书的有效天数）
$ openssl x509 -req -days 365 -in "/home/gitlab/ssh/gitlab.example.com.csr" -signkey "/home/gitlab/ssh/gitlab.example.com.key" -out "/home/gitlab/ssh/gitlab.example.com.crt"

# 创建pem证书（注意：这个创建时间可能比较长）
$ openssl dhparam -out "/home/gitlab/ssh/dhparams.pem" 2048
```

#### 四、配置 [vi /etc/gitlab/gitlab.rb] Gitlab证书密钥（注意：要修改其它配置也在是这个文件）
```bash
# 开启HTTP转HTTPS
nginx['redirect_http_to_https'] = true
# 配置crt证书
nginx['ssl_certificate'] = "/home/gitlab/ssh/gitlab.example.com.crt"
# 配置证书key
nginx['ssl_certificate_key'] = "/home/gitlab/ssh/gitlab.example.com.key"
# 配置pem证书
nginx['ssl_dhparam'] = "/home/gitlab/ssh/dhparams.pem"
```

#### 五、构建并初始化Gitlab以及配置
```bash
$ gitlab-ctl reconfigure
```

#### 六、修改[vi /var/opt/gitlab/nginx/conf/gitlab-http.conf] Nginx代理转发到Gitlab相关配置
```bash
server {
  listen *:80;
  server_name gitlab.example.com;
  # 添加HTTPS请求重定向
  rewrite ^(.*)$ https://$host$1 permanent;
}

# 最后执行下面的命令使配置生效（其实就是重启服务包括Nginx）
$ gitlab-ctl restart
```


```bash
$ systemctl start postfix
$ systemctl enable postfix
```





