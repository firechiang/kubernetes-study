```bash
http {
    # 缓存flush到磁盘的地址配置，以下是属性说明
    # path（缓存文件存放路径）
    # levels（path的目录层级）
    # use_temp_path（如果值是off就直接使用path路劲，如果值是on就使用proxy_temp_path路劲（建议直接配置成off））
    # keys_zone（名称是共享内存的名称（名称可以顺便起），size是共享内存的大小）
    # inactive（在指定时间内没有被访问的缓存会被清理（默认10分钟））
    # max_size（缓存文件最大大小，超过将由CM清理）
    # manager_files（CM清理一次清理缓存文件，最大清理数（默认100）；注意：CM是Nginx缓存管理进程）
    # manager_sleep（CM清理一次后进程的休眠时间默认200毫秒；注意：CM是Nginx缓存管理进程）
    # manager_threshold（CM清理一次最长耗时，默认50毫秒；注意：CM是Nginx缓存管理进程）
    # loader_files（CL载入文件到共享内存，每批最多文件数，默认100；注意：CL是Nginx缓存加载进程（就是将磁盘文件数据加载到内存当中））
    # loader_sleep（CL加载缓存文件到内存后，进程休眠时间，默认200毫秒；注意：CL是Nginx缓存加载进程（就是将磁盘文件数据加载到内存当中））
    # loader_threshold（CL每次载入文件到共享内存的最大耗时，默认50毫秒；注意：CL是Nginx缓存加载进程（就是将磁盘文件数据加载到内存当中））
    proxy_cache_path /data/nginx/cache levels=1:2 keys_zone=aaa_name:10m max_size=32g inactive=60m use_temp_path=off;

    server {
        # 如果请求是以txt或text结尾的就将$cookie_name的值设置为"no cache"
        if($request_uri ~ \.(txt|text)$ ) {
            set $cookie_name "no cache";
        }
        # 注意：下面的配置可以配置在server或http段
        location /test_proxy {
            # 是否开启代理缓存（就是缓存目标服务器的结果）
            proxy_cache off;
            # 缓存数据的key（下面的形式是：协议+域名+请求地址）
            proxy_cache_key $scheme$host$request_uri;
            # 对上游服务器响应200，301，302码做缓存，缓存时间是60分钟
            proxy_cache_valid 200 301 302 60m;
            # 如果Nginx内置变量 $cookie_name是有值的该请求就不使用缓存
            proxy_no_cache $cookie_name;
            # 如果Nginx内置变量 $cookie_name是有值的该请求就使用缓存（注意：这个配置和proxy_no_cache是相反的）
            #proxy_cache_bypass $cookie_name;
            # 是否开启合并相同请求（同时有多个请求同一资源的请求上来，是否只请求一次上游服务器，然后全部返回）
            proxy_cache_lock on;
            # 合并相同请求后，请求上游服务器的超时时间，如果超时了，每个请求都将被转发到上游服务器
            proxy_cache_lock_timeout 5s;
            # 合并相同请求后，请求上游服务器超时，过多久后再次发起一个请求到上游服务器（注意：如果一直超时，它会在间隔时间后一直发）
            # 说明：该配置是为了解决合并相同请求后上游服务器超时，避免所有相同请求都被转发到上游服务器
            proxy_cache_lock_age 1s;
            # 在上有服务器返回什么状态下使用已过期的缓存（默认off=不启用），可选值 error | timeout | invalid_header（无效头部） | updating（缓存过期正在更新） | http_500 | http_502 | http_503 | http_504 | http_403 | http_404 | http_429 | off 
            proxy_cache_use_stale off;
            # 在返回的结果当中添加一条头信息，标识是否命中缓存（$upstream_cache_status=是Nginx的内置变量表示是否命中缓存）
            add_header Nginx-Cache-Status "$upstream_cache_status";
	    # 请求 test_proxy 代理到 http://test_test/proxy（注意：test_test 是我们配置好的目标服务）
            # 注意：上游服务的URL末尾不带/，转发时会将完整的URL传到上游服务（比如请求/proxy/abc/test.html，经代理后转发到上游URL依然是/proxy/abc/test.html）
	    proxy_pass http://test_test/proxy;
	}
	# 请求以clear_cache开头，后面跟要清除缓存的请求地址，即可清除该请求地址的缓存数据
	# 注意：proxy_cache_purge 指令需要Nginx包含有ngx_cache_purge模块，否则无法使用
	location ~ /clear_cache(/.*) {
	    # $scheme$proxy_host$1 就是要清除缓存的key，$1就是正则表达式匹配到的要除缓存的请求地址（注意：我们上面配置的缓存key规则是 $scheme$host$request_uri）
	    proxy_cache_purge cache_zone $scheme$host$1;
        }
    }
}
```
