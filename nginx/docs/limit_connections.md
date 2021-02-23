```bash
http {
    # 记录连接数的共享内存，内存越大记录的连接数就越多，该配置用于限速使用（记录key的名称叫 limit_addr，内存大小10m，$binary_remote_addr表示一个IP一个连接）
    #limit_conn_zone $binary_remote_addr zone=limit_addr:10m;
    
    server {
    
        location / {
                # 开启限速（limit_addr是记录连接数的内存空间的名称（我们在上面配置了），2 表示限制连接数量）
            #limit_conn limit_addr 2;
               # 限速产生时返回给前端的状态码
            #limit_conn_status 503;
            # 限速产生时打印的日志级别
            #limit_conn_log_level warn;
            # 请求响应数据传输速率（每秒传输150个字节）注意：这个一般不配置，这个配置用于测试限速，有了这个配置响应就比较慢，就能查看限速是否生效
            #limit_rate 150;
        }
    }
}
```