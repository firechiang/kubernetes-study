#### 请求某个需要鉴权的地址，Nginx会先请求鉴权服务，当鉴权服务返回HTTP 200 状态码，才会允许请求通过（注意：使用第三方鉴权服务控制用户访问Nginx需要将http_auth_request_module模块编译进Nginx才能使用）
```bash
http {
    server {
        # 请求该地址需要鉴权 （注意：下面的配置可以配置在server或http段）
        location /private/ {
            # 开启鉴权（其实就是配置鉴权服务地址，因为测试鉴权服务,所以鉴权地址也是Nginx本机的地址，正常的话一般是外部地址）关闭的话直接配置off即可 
	    auth_request /auth;
	}
	# 鉴权服务（注意：下面的配置可以配置在server或http段）
        location /auth {
            # 转发地址（注意：这个其实就是当你请求鉴权服务时会被代理到下面的这个地址，也就是下面的地址才是真正的鉴权服务地址）
            proxy_pass http://127.0.0.1:8080/verify;
	    proxy_pass_request_body off;
	    proxy_set_header Content-Length "";
	    proxy_set_header X-Original-URI $request_uri;
        }
    }
}
```
