#### 一、下载Nginx以及相关源码（注意：pcre和zlib模块如果在本地已经安装了就不用下载了）
```bash
# 定位到Nginx目录
$ cd /home/chiangfire/data-dev/nginx
# 下载 Nginx源码
$ wget https://github.com/nginx/nginx/archive/release-1.19.7.tar.gz
# 下载pcre库源码（nginx正则表达式会用到）
$ wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
# 下载zlib库源码（nginx gzip模块会用到）
$ wget http://www.zlib.net/zlib-1.2.11.tar.gz

# 解压
$ tar -zxvf release-1.19.7.tar.gz
$ tar -zxvf pcre-8.44.tar.gz
$ tar -zxvf zlib-1.2.11.tar.gz

# 修改nginx源码目录名称
$ mv nginx-release-1.19.7 nginx-source-1.19.7
```

#### 二、编译安装（注意：pcre和zlib模块如果在本地已经安装了就不用编译了）
```bash
# 进入nginx源码目录的auto目录（注意：编译脚本configure就在这个目录下）
$ cd /home/chiangfire/data-dev/nginx/nginx-source-1.19.7
# 查看编译脚本configure的使用方式（注意：--with开头的模块默认是没有被编译进nginx的，--without开头的模块是默认编译进nginx的）
$ ./auto/configure --help

# 检查nginx编译环境生产Makefile文件，下面是配置参数（注意：--with开头的模块表示要编译进nginx，--without开头的模块表示不编译进nginx）
# --prefix         指定安装目录
# --sbin-path      指定运行程序存放目录（就是最终编译完成的程序存放目录，注意：如果没指定就默认在nginx安装目录）
# --user           运行nginx的work（工作）进程的属主
# --group          运行nginx的work（工作）进程的属组
# --pid-path       存放进程运行pid文件的路劲（注意：如果没指定就默认在nginx安装目录下）
# --conf-path      配置文件nginx.conf的存放目录（注意：如果没指定就默认在nginx安装目录下的conf目录）
# --error-log-path 错误日志的存放目录（注意：如果没指定就默认在nginx安装目录下logs目录）
# --http-log-path  访问日志access.log的存放目录（注意：如果没指定就默认在nginx安装目录下logs目录）
# --with-pcre      pcre库的存放目录，正则表达式会用到（注意：如果机器里面装了pcre就不需要指定目录，直接写--with-pcre即可）
# --with-zlib      zlib库的存放目录，gzip模块会用到（注意：如果机器里面装了zlib就不需要指定目录，直接写--with-zlib即可）
# 注意：编译环境检查过程中没提示错误，最后显示 Configuration summary 说明检查完成，会生成一个Makefile文件
$ ./auto/configure --prefix=/home/chiangfire/data-dev/nginx/nginx-1.19.7         \
                   --with-pcre=/home/chiangfire/data-dev/nginx/pcre-8.44         \
                   --with-zlib=/home/chiangfire/data-dev/nginx/zlib-1.2.11       \
                   --with-http_ssl_module                                        \
                   --with-http_v2_module                                         \
                   --with-http_image_filter_module                               \
                   --with-http_stub_status_module
# 执行编译
$ make

# 安装Nginx（注意：安装完成可到 /home/chiangfire/data-dev/nginx/nginx-1.19.7 目录查看生成的相关文件）
$ make install
```

#### 三、修改[/home/chiangfire/data-dev/nginx/nginx-1.19.7/conf/nginx.conf] Nginx主要配置文件
```bash
# 指定pid文件存放路径
#pid /home/chiangfire/data-dev/nginx/nginx-1.19.7/logs/nginx.pid;

# nginx工作进程使用哪个用户启动（注意：如果没有nginx用户，请使用命令：sudo useradd -g nginx -r -s /sbin/nologin nginx 添加nginx用户）
user nginx;

# 工作进程启动数量（可以指定数字，是几就启动几个；auto表示有几个CPU就启动几个）
worker_processes auto;
# 单个进程可用文件描述数（文件句柄数）
#worker_rlimit_nofile 20480;

# work(工作进程)异常终止原因信息文件大小
worker_rlimit_core 50M;
# work(工作进程)异常终止原因信息文件存放目录
working_directory /home/chiangfire/data-dev/nginx/nginx-1.19.7/error;

# 将每个work（工作进程）与CPU的物理核心进行绑定，避免同一个子进程在不同的CPU核心上切换，缓存失效，降低性能（注意：可使用命令 lscpu 查看cpu信息）
# 4个物理核心，4个work（工作）进程配置
#worker_cpu_affinity 0001 0010 0100 1000;
# 8个物理核心，8个work（工作）进程
#worker_cpu_affinity 00000001 00000010 00000100 00001000 00010000 00100000 01000000 10000000;
# 两个物理核心，4个work（工作）进程配置
#worker_cpu_affinity 01 10 01 10;

# 指定work（工作进程）的nice值，以调整运行nginx的优先级，通常设定为负值，以系统优先运行nginx（注意：范围是-20到19，值越小优先级越高。Linux默认优先级是120）
#worker_priority -10;

# work（工作）进程优雅退出的超时时间
worker_shutdown_timeout 60s;

# work（工作）进程内部使用的计时器精度，调整时间间隔越大，系统调用越少（频繁获取系统时间比较消耗CPU）
timer_resolution 100ms;

# nginx运行方式，on后台运行，off前台运行（注意：nginx默认是后台运行）
#daemon on;

 # 负载均衡互斥锁文件存放路径
lock_file /home/chiangfire/data-dev/nginx/nginx-1.19.7/logs/nginx.lock;

events {
    # nginx使用哪种事件驱动模型来处理连接，默认没有配置，建议不配置让Nginx自动选择（可选值 select,poll,kqueue,epoll,/dev/poll,eventport）
    #use epoll;
     # 单个Work（工作）进程最大处理请求数
    worker_connections 65535;
     # 是否打开负载均衡互斥锁（推荐打开） on 是，off 否
    accept_mutex on;
     # 新连接分配给work（工作）进程的超时时间（默认500ms），该配置生效的前提是 accept_mutex（负载均衡互斥锁） 以打开
    accept_mutex_delay 200ms;
    # work(工作)进程是否可以接收新连接（推荐打开，但是打开对性能的影响也不大，默认是关闭的） on 是，off 否（注意：默认一个work（工作）进程只能处理一个连接，只有打开了下面的参数才会处理多个连接）
    multi_accept on;
}

http {
    # 以下的单个配置也可以出现在server里面，只不过在server里面优先级更高
    include      mime.types;
    default_type application/octet-stream;
    charset      utf-8;
	
    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';
	
    #access_log  logs/access.log  main;
	
    sendfile        on;
    #tcp_nopush     on;
	
    # 长连接超时时间（单位秒）;
    keepalive_timeout  65;
	
    #gzip  on;
    # 单个Server端配置（注意：可以配置多个Server端；服务主机名或域名的匹配优先级是  1 精确匹配（优先级最高），2 左侧通配符匹配，3 右侧通配符匹配，4 正则表达匹配）
    server {
        # 服务监听地址（可写域名）和端口（注意：没写地址默认是0.0.0.0，没写端口默认是80）
	listen       127.0.0.1:80;
	# 服务主机名或域名（可以写多个用空格隔开，可以用通配符配置比如 *.nginx.com或~^www\.nginx\..*$。(注意：~开头表示以正则表达式方式匹配)）
	# 匹配的优先级是 1 精确匹配，2 左侧通配符匹配，3 右侧通配符匹配，4 正则表达匹配
        server_name  localhost;
	
	# 不带字符匹配地址（匹配优先级5（最最低））
        location / {
            # 前端请求 /admin 会映射到 html/admin文件夹，html默认是nginx安装目录下的文件夹，可以写绝对路径。 (说明：比如请求/index.html就会映射到html文件夹下的index.html文件)
            root  html;
            index index.html index.htm;
        }
	# 不带字符匹配地址（匹配优先级5（最最低））
	# 注意：地址最后没有带/，表示把/index当成目录地址也当成文件地址处理（就是如果直接访问/index，会在/的映射目录下找index文件。也可以使用/index/test/i.html找下级目录的文件）
        location /index {
            # 前端请求/会直接映射到 /html/index.html 文件（注意：映射地址最后要加/，还有这个配置和root配置互斥）
            alias /html/index.html/;
        }
	# = 表示精准匹配地址(注意：这个可以匹配到以/index1/开头的地址)（匹配优先级1（最高））
	# 注意：地址最后带了/，表示只把/index1当成目录地址处理，而不是文件地址（就是如果直接访问/index1，不会在/的映射目录下找index1文件，而是会返回404。只能使用/index1/test/i.html找下级目录的文件）
	location = /index1/ {
            root  html;
            index index.html index.htm;
        }
	# ^~ 表示匹配到即停止搜索地址（比如请求 /index4/test 地址会直接返回/index4数据，因为/index4已经匹配到了，它就会停止向下搜索）（匹配优先级2（其次））
	location ^~ /index4 {
            root  html;
            index index.html index.htm;
        }
        # ~ 表示以正则表达式区分大小写匹配地址（匹配优先级3（较低））
	location ~ \.(jpeg|jpg)$ {
            root  html;
            index index.html index.htm;
        }
	# ~* 表示以正则表达式不区分大小写匹配地址（匹配优先级4（最低））
	location ~* \.(jpeg|jpg)$ {
            root  html;
            index index.html index.htm;
        }
	
	# 配置当前server段nginx监控api的地址，就是客户端请求这个地址会得到nginx监控的相关信息如下
	# Active Connections 活跃的连接数（包括正在处理和等待处理的连接数），在nginx服务器里面想要获取该值，它的内嵌变量是${connections_active}
	# accepts            已接受的客户端连接总数量（累计增加）
	# handled            已处理的客户端连接总数量（累计增加）
	# requests           客户端总的请求数（累计增加）
	# Reading            读取客户端数据的连接数（就是正在接收客户端数据的连接数），在nginx服务器里面想要获取该值，它的内嵌变量是${connections_reading}
	# Writing            响应数据到客户端的连接数（就是正在发送数据到客户端的连接数），在nginx服务器里面想要获取该值，它的内嵌变量是${connections_writing}
	# Waiting            正在等待处理的请求连接数，在nginx服务器里面想要获取该值，它的内嵌变量是${connections_waiting}
	location /monitor_api {
	    # 标识该地址是监控api（注意：如果nginx的版本低于1.7.5请使用 stub_status on 开启监控api）
	    # 注意：这个需要在nginx编译期间将该模块编译进nginx才可以使用（可使用命令 nginx -V 查看是否有 --with-http_stub_status_module 参数来判断该模块是否已被编译进nginx）
	    stub_status;
        }
    }
}
```

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
