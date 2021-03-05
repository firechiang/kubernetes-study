```bash
http {
    server {
        # 请求该地址需要鉴权 （注意：下面的配置可以配置在server或http或location段）
        location /download/ {
            # 请求所映射的数据目录 
	    root /home/source;
	    # 开启文件目录模块（默认是关闭的）
	    autoindex on;
	    # 是否显示文件大小（默认是不显示的）
	    autoindex_exact_size on;
	    # 文件目录以什么形式返回，可选 html | xml | json | jsonp
	    autoindex_format html;
	    # 是否显示时间
	    autoindex_localtime off;
	}
    }
}
```
