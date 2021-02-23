#### 一、[Nginx编译安装][1]
#### 二、[Nginx配置相关说明][2]
#### 三、[限制Connection连接数量简单使用][3]
#### 四、[限制客户端的请求速率（漏斗算法限流，一大堆流量先到漏斗里，然后通过漏斗的最大流出速率，处理请求）简单使用和漏斗算法说明][4]

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


[1]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/compile_install.md
[2]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/config_description.md
[3]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/limit_connections.md
[4]: https://github.com/firechiang/kubernetes-study/blob/master/nginx/docs/limit_request.md
