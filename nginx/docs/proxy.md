#### Nginx反向代理所支持的协议
 - tcp/udp
 - fastcgi
 - scgi
 - uwsgi
 - http
 - grpc
 - memcached
 - websocket
 
#### 代理配置示列 
```bash
http {
    
    # 配置一个上游服务（代理目标服务）（test_test=服务名称，可以随便起）
    upstream test_test {
        # 目标服务器（注意：目标服务器可以配置多个，也可以写域名）
	# weight=负载均衡的权重（默认是1，只有轮训负载均衡算法起作用，也就是没有配置负载均衡算法）
	# max_conns=目标服务最大并发连接数
	# max_fails=目标服务不可用的判断次数（规定时间内请求服务N次都不可用，表示服务不可用，该参数是配合fail_timeout参数一起使用的）
	# fail_timeout=目标服务不可用的判断时间（就是该时间内请求服务max_fails次都不可用，表示该服务不可用）
        server 192.168.184.20:8080 weight=2 max_conns=1000 fail_timeout=10s max_fails=3;
	
	#server 192.168.184.20:8081 weight=2 max_conns=1000 fail_timeout=10s max_fails=3;
	
	# backup=备用服务器，仅当其他服务器都不可用时，才启用（就是当上面配置的服务器都不可用时，才启用这个服务）
	#server 192.168.184.20:8080 backup;
	
	# down=标记服务器长期不可用，离线维护
	#server 192.168.184.20:8082 down;
	
	# 配置hash负载均衡算法（下面是通过请求地址的hash值来做转发规则的，也就是相同的请求地址都会转发到同一台上游服务器）
	# 注意：$request_uri 是Nginx的内置变量，这里也可以填写别的内置变量，填写别的也就是通过别的值来做hash转发规则
	#hash $request_uri;
	
	# 配置ip hash负载均衡算法（只要客户端的IP相同都会转发到同一台上游服务器）
	#ip_hash;
	
	# 分配跨Work子进程共享内存空间（就是用来存储一些Work进程共享的数据，注意：如果配置了最少连接数的负载均衡算法，就需要配置这个，因为没有Work子进程的连接数需要共享）
        #zone test 10M;
	# 最少连接数负载均衡算法（就是哪台服务器连接数最少就转发到哪台服务器上）
	#least_conn;

	# 启用目标服务长连接，注释掉该配置表示不启用目标服务长连接（16表示最大空闲长连接的个数，注意：该值不要设置太大）
	keepalive 16;
	
	# 目标服务一个长连接最多请求个数（就是同一个长连接最多可以发起多少次请求）
	keepalive_requests 80;
	
	# 空闲长连接的最长保持时间
	keepalive_timeout 20s;
    } 
	
    # 是否开启将请求一次性转发给目标服务器，默认是开启的（注意：该配置可以配置在server或http和location段）
    # on=开启（就是Nginx接收到客户端请求的所有数据之后才转发到目标服务，开启时Nginx会默认开启一个缓冲区用来存储客户端请求的数据）
    # off=不开启（就是Nginx接收到客户端请求数据就立即转发给目标服务）
    # 该配置的适用场景：吞吐量要求高，但是上游服务器并发处理能低
    proxy_request_buffering on;
	
    server {
        location /test_proxy  {
            # 请求 test_proxy 代理到 http://test_test/proxy（注意：test_test 是我们在上面就配置好的目标服务）
            # 注意：上游服务的URL末尾不带/，转发时会将完整的URL传到上游服务（比如请求/proxy/abc/test.html，经代理后转发到上游URL依然是/proxy/abc/test.html）
	    proxy_pass http://test_test/proxy;
	        
	    # 代理请求时所使用的方法（这个一般不配置，默认使用客户端所请求的方法）
	    #proxy_method GET;
	
	    # 代理请求时使用的HTTP版本号，可选值 1.0|1.1 （这个一般不配置，默认使用客户端所使用的HTTP版本号）
	    #proxy_http_version 1.1;
	    
	    # 代理请求时添加固定头信息（注意：若value为空，则不会将添加的固定头信息发送到上游服务器）
	    #proxy_set_header aaa value;
	    
	    # 固定头信息可以写多个
	    #proxy_set_header bbb value;
	    
	    # 代理请求时添加固定body信息
	    #proxy_set_body {};
	    
	    # 是否将客户端请求的body信息传递到上游服务on=是，off=否
	    #proxy_pass_request_body on;
	    
	    # 是否将客户端请求的头信息传递到上游服务on=是，off=否
	    #proxy_pass_request_headers on;
        }
       
        location /bbs/ {
            # 请求 bbs 代理到 http://127.0.0.1:8050/
            # 注意：上游服务的URL末尾带/，转发时location匹配部分会被删除掉（比如请求/bbs/abc/test.html，经代理后转发到上游的URL会变成/abc/test.html）
	    proxy_pass http://127.0.0.1:8050/;
        }
    }
}
``` 
