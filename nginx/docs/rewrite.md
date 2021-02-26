#### 使用正则表达式匹配请求地址的某一部分内容，然后将匹配到的内容重写为一个URL并重定向过去
```bash
http {
    # 请求该地址直接返回200（注意：下面的配置可以配置在server或http段或if段）
    server {
        # 将匹配到^(/download/.*)/media/(.*)\..*$的URL重定向到$1/mp3/$2.mp3（注意：$1是第一个正则表达匹配到的内容，$2是第二个正则表达匹配到的内容）
        # 注意：last是重定向类型，重定向类型有如下几种：
        # last 表示重写后的URL会发起新的请求，再次进入server段，重试location中的匹配
        # break  表示直接使用重写后的URL，不再匹配其他location中语句
        # redirect 表示返回302并临时重定向
        # permanent 表示返回301并永久重定向
        rewrite ^(/download/.*)/media/(.*)\..*$ $1/mp3/$2.mp3 last;
        # 最后都没有匹配到就直接返回404
        return  404;
    }
}
```
