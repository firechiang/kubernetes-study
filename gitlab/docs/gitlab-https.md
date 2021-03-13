#### 一、创建 Gitlab 证书密钥（注意：如果有公网证书这一步就不需要了）
```bash
$ mkdir -p /home/gitlab/ssh && cd /home/gitlab/ssh

# 创建密钥key
$ openssl genrsa -out "/home/gitlab/ssh/gitlab.test.com.key" 2048

# csr创建证书
$ openssl req -new -key "/home/gitlab/ssh/gitlab.test.com.key" -out "/home/gitlab/ssh/gitlab.test.com.csr"
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
Common Name (eg, your name or your server's hostname) []:gitlab.test.com
Email Address []:firechiang@outlook.com

Please enter the following 'extra' attributes
to be sent with your certificate request
# 证书密码（注意：不要写错了）
A challenge password []:jiang123456
# 公司名称
An optional company name []:jiang

# 使用密钥key和csr创建crt证书（注意：x509是crt证书的格式，365是crt证书的有效天数）
$ openssl x509 -req -days 365 -in "/home/gitlab/ssh/gitlab.test.com.csr" -signkey "/home/gitlab/ssh/gitlab.test.com.key" -out "/home/gitlab/ssh/gitlab.test.com.crt"

# 创建pem证书（注意：这个创建时间可能比较长）
$ openssl dhparam -out "/home/gitlab/ssh/dhparams.pem" 2048
```

#### 三、修改 [vi /etc/gitlab/gitlab.rb] 配置
```bash
# 绑定域名或IP（注意：协议是https，其实这个是Nginx绑定的域名或IP，因为要访问Gitlab其实是通过Nginx做代理转发的）
external_url 'https://gitlab.test.com'
# 开启HTTP重定向HTTPS（如果不开启就不暴露80端口，就只能通过HTTPS访问）
nginx['redirect_http_to_https'] = true

# 注释掉http端口配置（注意：一定要注释掉，因为开启https端口配置都需要用默认的，否则https端点将无法启动）
#nginx['listen_port'] = 80

# 配置crt证书
nginx['ssl_certificate'] = "/home/gitlab/ssh/gitlab.test.com.crt"
# 配置证书key
nginx['ssl_certificate_key'] = "/home/gitlab/ssh/gitlab.test.com.key"
# 配置pem证书（如果没有就不需要配置）
nginx['ssl_dhparam'] = "/home/gitlab/ssh/dhparams.pem"
# 证书颁发机构给的那串码（如果没有就不需要配置）
nginx['ssl_ciphers'] = "****************"
```

#### 四、重新配置Gitlab以及相关组件并重启相关服务
```bash
$ gitlab-ctl reconfigure
```