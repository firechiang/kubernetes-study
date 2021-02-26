```bash
http {
    server {
        # 请求该地址直接返回200（注意：下面的配置可以配置在server或http段）
        location /testest_200 {
	    return 200;
	      }
	    # 请求该地址直接返回：状态码 200，内容 “请求成功”
        location /testest_200 {
	    return 200 "请求成功";
	      }
	      
	      	    # 请求该地址直接重定向到 http://127.0.0.1:8080/index
        location /testest_url {
	    return http://127.0.0.1:8080/index;
	      }
	      	      	    # 请求该地址直接返回：状态码 302，重定向到 http://127.0.0.1:8080/index
        location /testest_url {
	    return 302 http://127.0.0.1:8080/index;
	      }
     }
}
```