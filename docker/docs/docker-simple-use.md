#### 一、基础命令
```bash
# 查看 docker 服务端和客户端相关版本
$ docker version

# 查看 docker 相关信息
$ docker info

# 搜索 docker 镜像
$ docker search "镜像名称"

# 下载或更新 docker 镜像（docker pull "镜像名称":"版本"）
$ docker pull "镜像名称"

# 删除镜像（注意：是删除镜像，不是容器）（docker rmi "镜像名称":"版本"）
$ docker rmi "镜像名称"

# 查看本地已下载的所有镜像
$ docker images

# 为镜像 zookeeper 打上tag <:3.5是镜像版本>
$ docker tag zookeeper:3.5 test/zookeeper:3.5

# 查看java镜像里面的所有环境变量
$ docker run java env

# 在java镜像里面执行命令 java -version
# docker run:执行镜像
# -it=打开命令终端，
# java=镜像名称
# java -version=打开命令终端后执行该命令
$ docker run -it java java -version

# 以命令行的方式进入 openjdk 镜像（注意：7-jre 是指定镜像的Tag(版本)，可以不写）
$ docker run -it --entrypoint bash openjdk:7-jre

# 以命令行的方式进入 openjdk 镜像（注意：-e是往镜像里面添加环境变量，在进入镜像以后可以使用，一般服务的配置也是通过这个传递的）
$ docker run -e AAA=jiang -it --entrypoint bash openjdk

# 启动Nginx镜像
# --name = 指定镜像启动后的名称（注意：是镜像启动后的名称而不是镜像的名称，还有这个名称可以不指定）
# -e = 往镜像里面添加环境变量，在进入镜像以后可以使用，一般服务的配置也是通过这个传递的
# -d = 镜像将会运行在后台模式
# -p = 将主机的80转发到镜像的80端口《可使用--net=host替代直接使用宿主机端口不做转发》
# -rm = 镜像运行完成后立即删除（注意：这个配置项请谨慎使用）
$ docker run  -e AAA=jiang --name nginx-test -d -p 80:80 nginx

# 停止容器运行（注意：容器运行ID可使用命令 docker ps 查看）
$ docker stop "容器运行ID"

# 查看所有容器
$ docker ps -a

# 查看当前正在运行的容器
$ docker ps

# 进入正在运行的容器（注意：如果报没有 bash 的错误，请使用命令：docker exec -it "容器运行ID" sh）
$ docker exec -it "容器启动后的名称 | 容器运行ID" bash

# 进入正在运行的容器（注意：attach会重新连接容器会话，而且断开后会停止 docker 镜像，所以不推荐使用）
#$ docker attach -it "容器启动后的名称 | 容器运行ID" bash

# 查看服务容器运行日志（注意：容器运行ID可使用命令 docker ps 查看，-f 表示跟随日志）
$ docker logs -f "容器运行ID"

# 将容器里面的文件/etc/nginx/nginx.conf文件，复制到当前目录（7f2bca7ba987=容器运行ID）
$ docker cp 7f2bca7ba987:/etc/nginx/nginx.conf ./

# 将容器创建为镜像（所有镜像可使用 docker images 命令查看）
$ docker commit "容器运行ID" "镜像名称"

# 删除镜像（注意：是删除镜像，不是容器）（docker rmi "镜像名称":"版本"）
$ docker rmi "镜像名称"

# 删除容器（注意：是删除容器，不是删除镜像。容器ID可使用命令 docker ps -a 查看）
$ docker rm '容器ID'
```

#### 二、Docker容器生命周期相关指令 create | start | stop | pause | unpause
```bash
# 创建一个 docker 容器名叫 myjava，后面的命令就是容器所要做的事情
$ docker create -it --name=myjava java java -version

# 查看所有容器
$ docker ps -a
	
# 启动刚刚创建的容器<测试>	
$ docker start myjava
	
# 创建一个名字叫mysql的容器，最后的mysql是镜像的名称
# -e = 往容器环境变量里面设值（一般服务的配置也是通过这个传递的），
# -p 3306:3306  = 将主机的3306转发到容器的3306端口《可使用--net=host替代直接使用宿主机端口不做转发》	
$ docker create --name=mysql -e MYSQL_ROOT_PASSWORD=jiang -p 3306:3306 mysql
	
# 启动刚刚创建的 mysql 容器（注意：容器ID可使用命令 docker ps -a 查看）
$ docker start '容器名称 || 容器ID'
	
# 进入正在运行的容器（如果报没有 bash 的错误，请使用命令：docker exec -it "容器运行ID" sh）
$ docker exec -it "容器启动后的名称 | 容器运行ID" bash

# 停止容器运行	
$ docker stop "容器启动后的名称 | 容器运行ID"

# 删除容器（注意：是删除容器，不是删除镜像。容器ID可使用命令 docker ps -a 查看）
$ docker rm '容器ID'
```

#### 三、推送Docker镜像到到仓库
```bash
# docker 登陆，然后提示 输入用户名，密码（默认登陆 hub.docker）
$ docker login

# 为镜像 zookeeper 打上tag <:3.5是镜像版本>
$ docker tag zookeeper:3.5 test/zookeeper:3.5

# 将zookeeper 镜像上传到仓库<:3.5是镜像版本>
$ git push test/zookeeper:3.5
```
