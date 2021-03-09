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
	
    # 客户端长连接超时时间（单位秒）;
    keepalive_timeout  65;
    
    # 是否开启gzip压缩
    #gzip  on;
    
    # Nginx可以处理的请求体的大小（默认是1M，如果要上传文件，建议调大一点，否则无法上传文件），该配置可在http, server, location段中
    #client_max_body_size 1M;
    
    # Nginx处理请求时body缓冲区的大小。32位系统默认是8k，64位系统默认是16k（建议看应用情款调大一点），该配置可在http, server, location段中
    #client_body_buffer_size 16k;
    
    # 是否将请求体的数据放置在缓冲区的一段连续内存当中（默认是关闭的），该配置可在http, server, location段中
    #client_body_in_single_buffer on;
    
    # 如果请求体的数据大于缓冲区的大小，那么数据将会放置在磁盘上，下面就是配置临时目录（这个目录都是相对Nginx的安装目录的），该配置可在http, server, location段中
    # client_body_temp 目录是Nginx启动后就会有的目录
    #client_body_temp_path client_body_temp;
    
    # 如果请求体的数据大于缓冲区的大小，是否将数据放置在磁盘上（注意：如果开启那么缓冲区将不起作用），该配置可在http, server, location段中
    # 如果配置 clean 数据将会放置在磁盘上，请求完成数据删除
    #client_body_in_file_only off;
    
    # 接收客户端请求体数据的超时时间，该配置可在http, server, location段中
    #client_body_timeout 60s;
    
    # 代理转发时连接上游服务器超时时间，该配置可在http, server, location段中
    #proxy_connect_timeout 60s;
    
    # 代理转发时是否开启TCP层的长连接（系统层长连接，非应用层），该配置可在http, server, location段中
    #proxy_socket_keepalive off;
    
    # 代理转发时向上游服务器发送数据的超时时间（就是规定时间内没有发送数据，就断开连接），该配置可在http, server, location段中
    #proxy_send_timeout 60s;
    
    # 代理转发时接收上游服务器返回数据的超时时间（就是规定时间内没有收到数据，就断开连接），该配置可在http, server, location段中
    #proxy_read_timeout 10s;
    
    # 代理转发时是否忽略客户端关闭连接的指令（就是浏览器向Nginx发送关闭连接的指令，该指令是否不发送给上游服务器；如果开启，浏览器和Nginx断开了，Nginx和上游服务器的连接将不会断开）
    # 注意：该配置建议设置成off,该配置可在http, server, location段中
    #proxy_ignore_client_abort off;
    
    # 代理转发时,上游服务发生错误时，返回什么状态给客户端，可以配置多个（默认是error和timeout，也可以配置off就是关闭该功能）
    # 可选值如下，建议配置成off（该配置可在http, server, location段中）
    # timeout （当上游服务连接或读取超时时，它默认会将请求再次转发到其它的服务器上（注意：不推荐使用该配置，因为超时时会将请求再次转发到其它服务器上去））
    # error（当上游服务拒绝连接时，它默认会将请求再次转发到没有挂的服务器上）
    # invalid_header（上游服务器返回无效的响应）
    # http_500 | http_502 | http_503 | http_504 | http_403 | http_404 | http_429
    # non_idempotent（非幂等请求上游服务异常时，是否要转发到其它服务器上）
    # off（关闭该功能）
    #proxy_next_upstream off;
    
    # 单个Server端配置（注意：可以配置多个Server端；服务主机名或域名的匹配优先级是  1 精确匹配（优先级最高），2 左侧通配符匹配，3 右侧通配符匹配，4 正则表达匹配）
    server {
        # 服务监听地址（可写域名）和端口（注意：没写地址默认是0.0.0.0，没写端口默认是80）
	listen       127.0.0.1:80;
	# 服务主机名或域名（可以写多个用空格隔开，可以用通配符配置比如 *.nginx.com或~^www\.nginx\..*$。(注意：~开头表示以正则表达式方式匹配)）
	# 匹配的优先级是 1 精确匹配，2 左侧通配符匹配，3 右侧通配符匹配，4 正则表达匹配
        server_name  localhost;
	
	# 不带字符匹配地址（location匹配优先级5（最最低））
        location / {
            # 前端请求 /admin 会映射到 html/admin文件夹，html默认是nginx安装目录下的文件夹，可以写绝对路径。 (说明：比如请求/index.html就会映射到html文件夹下的index.html文件)
            root  html;
            index index.html index.htm;
        }
	# 不带字符匹配地址（location匹配优先级5（最最低））
	# 注意：地址最后没有带/，表示把/index当成目录地址也当成文件地址处理（就是如果直接访问/index，会在/的映射目录下找index文件。也可以使用/index/test/i.html找下级目录的文件）
        location /index {
            # 前端请求/会直接映射到 /html/index.html 文件（注意：映射地址最后要加/，还有这个配置和root配置互斥）
            alias /html/index.html/;
        }
	# = 表示精准匹配地址(注意：这个可以匹配到以/index1/开头的地址)（location匹配优先级1（最高））
	# 注意：地址最后带了/，表示只把/index1当成目录地址处理，而不是文件地址（就是如果直接访问/index1，不会在/的映射目录下找index1文件，而是会返回404。只能使用/index1/test/i.html找下级目录的文件）
	location = /index1/ {
            root  html;
            index index.html index.htm;
        }
	# ^~ 表示匹配到即停止搜索地址（比如请求 /index4/test 地址会直接返回/index4数据，因为/index4已经匹配到了，它就会停止向下搜索）（location匹配优先级2（其次））
	location ^~ /index4 {
            root  html;
            index index.html index.htm;
        }
        # ~ 表示以正则表达式区分大小写匹配地址（location匹配优先级3（较低））
	location ~ \.(jpeg|jpg)$ {
            root  html;
            index index.html index.htm;
        }
	# ~* 表示以正则表达式不区分大小写匹配地址（location匹配优先级4（最低））
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
