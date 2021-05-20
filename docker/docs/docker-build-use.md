#### 一、创建 [vi Dockerfile] 文件，内容如下
```bash
# 'FROM' 在某个基础镜像之上进行扩展。（可以指定私有仓库：192.168.83.131:80/test-service/centos:latest）《:latest是版本》
FROM centos
# 'MAINTAINER' 镜像创建者
MAINTAINER chiangfire@outlook.com
# 'ADD' 添加 nginx-1.12.2.tar.gz 文件到 /usr/local/src
ADD nginx-1.12.2.tar.gz /usr/local/src
# 'EXPOSE' 镜像开放6379端口
EXPOSE 6379
# 'ENTRYPOINT' 镜像启动时要执行的命令，必须是前台执行的方式，一般都是自己的应用系统启动命令
ENTRYPOINT java -version
# 'ENV' 添加环境变量
ENV JAVA_HOME /usr/lib/java-8
# 创建镜像时会执行的命令《比如安装软件》多条命令可使用 \ 换行，下一行使用 && 开头，整个Dockerfile最好只有一个RUN因为每个RUN都是一层镜像
RUN '创建镜像会执行的命令《比如安装软件》'
```

#### 二、构建Docker镜像
```bash
# chiangfire  = Docker镜像仓库账户ID（注意：可直接写仓库地址如：192.168.83.131:80/test-service/openjdk:9-jre，还有ID后面还可以使用 /xxx添加层级）
# centos-test = 镜像名称
# :0.0.1          =  镜像版本，
# .           = Dockerfile所在目录（.表示当前目录）
$ docker build -t chiangfire/centos-test:0.0.1 .
```
