#### 一、[Nginx编译安装][1]
#### 二、[Nginx配置相关说明][2]
#### 三、[限制Connection连接数量简单使用][3]
#### 四、[限制处理客户端请求的速度（漏斗算法限流，一大堆流量先到漏斗里，然后通过漏斗的最大流出速率，处理请求）简单使用和漏斗算法说明][4]
#### 五、[限制特定IP或网段访问简单使用][5]
#### 六、[配置用户访问简单使用][6]
#### 七、[使用第三方鉴权服务控制用户访问Nginx][7]
#### 八、[return配置简单使用（就是直接返回信息）][8]
#### 九、[rewrite配置简单使用（使用正则表达式匹配请求地址的某一部分内容，然后将匹配到的内容重写为一个URL并重定向过去）][9]
#### 十、[if配置简单使用（就是通过判断语句执行对应逻辑）][10]
#### 十一、[autoindex文件目录模块简单使用（就是当用户请求以/结尾时，列出目录结构还可下载文件）][11]
#### 十二、[反向代理相关配置说明以及简单使用][12]
#### 十三、[缓存相关配置][13]
#### 十四、[https相关配置][14]

#### 四、Nginx进程结构（注意：Nginx启动后会有两种进程）
 - Master Process（主进程（root用户管理），用于监控Worker process（工作进程），并自动管理工作进程（比如工作进程挂了，主进程会自动启动它））
 - Worker process（工作进程，用于接收处理用户请求）（注意：工作进程挂了之后，主进程会立即重启一个新的工作进程。可以使用命令： kill -s SIGTERM "工作进程ID" 杀死一个工作进程，测试看看是否会有新的工作进程被启动）
 

#### 五、启动停止Nginx（注意：如果nginx要绑定80端口，那么就是需要使用root权限启动，因为linux要绑定1024以下的端口，需要root权限；Nginx的Work（工作）进程不能被杀死）
```bash
# 查看Nginx的版本以及安装目录，配置文件目录，日志目录
$ nginx -V

# 指定配置文件启动nginx
# nginx -c /usr/local/nginx/conf/nginx.conf
# 注意：没有指定配置文件默认加载nginx安装目录conf文件夹下的nginx.conf配置文件
$ nginx

# 重新加载nginx配置文件（原理：Nginx使用新的配置文件启动新的工作进程，完成后再优雅停止旧的工作进程（可以查看配置文件加载前后的工作进程ID来验证））
$ nginx -s reload  

# 优雅停止nginx
$ nginx -s quit

# 强制停止nginx
$ nginx -s stop

# 测试配置文件是否正确
$ nginx -t
```

#### 六、Nginx热更新（注意：首先要将旧的Nginx文件替换成新的Nginx文件，数据目录保持新旧一致（注意备份旧的Nginx文件））
```bash
# 查看Nginx所有的进程信息
$ ps -ef | grep nginx | grep -v grep
root     16763     1  0 15:06 ?        00:00:00 nginx: master process /usr/sbin/nginx -g daemon off;
nginx    19101 16763  0 16:04 ?        00:00:00 nginx: worker process

# 发送信息号给旧Nginx主进程，让其再启动一套Nginx（注意：这个命令执行完成以后再查看Nginx进程信息会看到有两套Nginx进程信息（新旧Nginx并存了），一个是旧的一个是新的）
# 注意：旧的Nginx PID文件会变成 nginx.pid.oldbin（其实就是在后面加了个oldbin）
$ kill -s SIGUSR2 16763

# 发送信息号给旧Nginx主进程，让其停止所有旧的工作进程（注意：这个时候旧Nginx的主进程还在，只是工作进程都停了，当然请求也会被新的Nginx所接收）
# 注意：这一步完成以后要测试看看新的Nginx接收请求会不会有问题
$ kill -s SIGWINCH 16763

# 如果新的Nginx接收请求有问题，发送信息号给旧Nginx主进程，让旧Nginx的工作进程都启动起来（重新使用旧的Nginx，相当于回滚的操作）
# 注意：如果要回滚，这条命令执行完成以后，再执行：kill -s SIGQUIT “新Nginx主进程PID” 命令来停止新Nginx
$ kill -s SIGHUP 16763

# 如果新Nginx没有问题，就停止旧的Nginx主进程（注意：这一步完成以后，查看旧的Nginx主进程是否停止，如果停止了表示Nginx升级成功）
$ kill -s SIGQUIT 16763
```
#### 、Nginx内置变量简单说明
 - $http_user_agent（获取浏览器的 user_agent；注意：Nginx可能修改这个值）
 - $remote_addr（客户端的IP地址）
 - $remote_port(客户端端口)
 - $binary_remote_addr（二进制格式的客户端IP地址）
 - $connection（TCP连接的序号，自动递增）
 - $connection_request（TCP当前的请求数）
 - $proxy_protocol_addr（若使用了proxy_protocol代理协议，则返回协议中的地址，否则返回空）
 - $proxy_protocol_port（若使用了proxy_protocol代理协议，则返回协议中的端口，否则返回空）
 - $server_addr（服务端IP地址）
 - $server_port（服务端端口）
 - $server_protocol（服务端协议）
 - $uri（请求的URL不包含参数）
 - $request_uri（请求的URL，包含参数）
 - $scheme（协议名称（http或https））
 - $request_method（请求方法）
 - $request_length（请求的全部长度（包含请求行，请求头，请求体））
 - $args（全部参数字符串）
 - $arg_参数名（特定参数值）
 - $is_args（URL中有参数，则返回?号，否则返回空）
 - $query_string（与agrs变量的值相同）
 - $remote_user（获取由HTTP Basic Authentication协议传入的用户名）
 - $host（获取域名，先看请求行，再看请求头，最后找server_name；注意：Nginx可能修改这个值）
 - $proxy_host（获取代理服务域名，先看请求行，再看请求头，最后找server_name；注意：Nginx可能修改这个值）
 - $http_referer（请求来源，从哪些链接过来的请求；注意：Nginx可能修改这个值）
 - $http_via（代理服务器信息，经过一层代理服务器，添加对应代理服务器的信息；注意：Nginx可能修改这个值）
 - $http_x_forwarded_for（获取用户真实IP；注意：Nginx可能修改这个值）
 - $http_cookie（用户cookie；注意：Nginx可能修改这个值）
 - $request_time（处理请求已耗费时间）
 - $request_completion（请求是否处理完成，已完成返回OK，否则返回空）
 - $server_name（获取请求server_name的值）
 - $https（若开启https，则返回on，否则返回空）
 - $request_filename（磁盘文件系统待访问文件的完成路径（比如下载文件就是请求所对应的磁盘文件所在的完整路径））
 - $document_root（由URL和root/alias规则生成的文件夹路径）
 - $realpath_root（将document_root中的软链接换成真实路径）
 - $limit_rate（获取返回响应时的速度上限值）
 - $upstream_cache_status（缓存是否命中：MISS=未命中缓存，HIT命中缓存，EXPIRED=缓存过期，STALE=命中了陈旧缓存，REVALIDDATED=Nginx验证陈旧缓存依然有效，UPDATING=内容陈旧，但正在更新，BYPASS=响应从原始服务器获取）
 - $cookie_name（获取cookie的名称）
 
#### 、HTTP协议重定向状态码说明
 - 301（永久重定向)
 - 302（临时重定向，禁止被缓存）
 - 303（临时重定向，禁止缓存，允许改变方法）
 - 307（临时重定向，禁止缓存，不允许改变方法）
 - 308（永久重定向，不允许改变方法）

[1]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/compile_install.md
[2]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/config_description.md
[3]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/limit_connections.md
[4]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/limit_request.md
[5]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/limit_ip.md
[6]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/limit_user.md
[7]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/authentication.md
[8]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/return.md
[9]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/rewrite.md
[10]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/if.md
[11]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/autoindex.md
[12]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/proxy.md
[13]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/cache.md
[14]: https://github.com/firechiang/kubernetes-study/blob/master/gitlab/docs/gitlab-https.md