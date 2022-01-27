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

# 安装编译依赖
$ sudo zypper in gcc-c++ libopenssl-devel gd-devel

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
