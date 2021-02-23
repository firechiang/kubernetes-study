#### 一、漏桶算法限制处理客户端请求的速度（漏斗算法限流，一大堆流量先到漏斗里，然后通过漏斗的最大流出速率，处理请求）
![image](https://github.com/firechiang/kubernetes-study/blob/master/nginx/images/leak_bucket.png)
#### Bursty Flow
 - 我们可以想象下生活中的场景，水龙头当作流量的来源，水龙头代表着突发量(Bursty Flow)。当网络中存在突发量，且无任何调控时，就会出现像Bursty Data处类似的场景。
 - 主机以12Mbps的速率发送数据，时间持续2s，总计24Mbits数据。随后主机暂停发送5s，然后再以2Mbps的速率发送数据3s，最终总共发送了6Mbits的数据。
 - 主机在10s内总共发送了30Mbits的数据。但这里存在一个问题，就是数据的发送并不是平滑的，存在一个较大的波峰。若所有的流量都是如此的传输方式，会出现"旱的旱死涝的涝死"，对系统并不是特别的友好。
 
#### Fixed Flow
 - 为了解决Bursty Flow场景的问题。已知：漏桶(Leaky Bucket)出现了，漏桶具有固定的流出速率、固定的容量大小。
 - 在上图中：漏桶在相同的10s内以3Mbps的速率持续发送数据来平滑流量。若水（流量）来的过猛，但是水流（漏水）不够快时，其最终结果就是导致水直接溢出，呈现出来的就是拒绝请求、排队等待的表现。另外当Buckets空时，是会出现一次性倒入达到Bucket容量限制的水可能性，此时也可能会出现波峰。
 - 简而言之：一个漏桶(漏斗)，水流进来，但漏桶只有固定的流速来流出水，若容量满即拒绝，否则将会持续保持流量流出。
 
#### 配置示列
```bash
http {
    # 记录请求数的共享内存，内存越大记录的请求数就越多，该配置用于限制处理速度使用
    # $binary_remote_addr表示一个IP一个请求
    # limit_req_addr 是记录key的名称叫 ，内存大小10m
    # 2r/s 表示每秒处理2个请求，500毫秒处理一个请求（以500毫秒处理一个请求的速度，去处理请求（简单理解：就是每500毫秒消费一个请求））
    limit_req_zone $binary_remote_addr zone=limit_req_addr:10m rate=2r/s;
    
    server {
        # 注意：以下配置如果写在server段表示限制所有的location处理速度；当然下面的配置是在location段，限制的是单个location
        location / {
            # 开启限速（limit_req_addr是记录请求数的内存空间的名称（我们在上面配置了）
            limit_req zone=limit_req_addr;
            #  开启限速（limit_req_addr是记录请求数的内存空间的名称（我们在上面配置了），burst=5 表示漏斗的大小，就是最多有多少个请求在等待处理，一般不建议配置漏斗大小）
        #limit_req zone=limit_req_addr burst=5;
            # 限速产生时返回给前端的状态码
            limit_req_status 503;
            # 限速产生时打印的日志级别
            limit_req_log_level warn;
            # 请求响应数据传输速率（每秒传输150个字节）注意：这个一般不配置，这个配置用于测试限速，有了这个配置响应就比较慢，就能查看限速是否生效
            limit_rate 150;
        }
    }
}
``` 