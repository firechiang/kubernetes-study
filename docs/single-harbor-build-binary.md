#### 一、[安装Docker](https://github.com/firechiang/kubernetes-study/blob/master/docker/docs/docker-online-install.md)

#### 二、下载安装半容器编排工具docker-compose
```bash
# 下载docker-compose到/usr/local/bin目录
$ curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose
# 为docker-compose添加可执行权限
$ chmod +x /usr/local/bin/docker-compose
# 检查docker-compose环境是否安装成功，查看docker-compose版本
$ docker-compose -version              
```
#### 三、下载和解压安装依赖包
```bash
# 下载Harbor-1.9.0安装包
$ wget -P /home/tools/harbor https://storage.googleapis.com/harbor-releases/release-1.9.0/harbor-offline-installer-v1.9.0.tgz

# 解压Harbor-1.9.0安装包到/home/harbor-1.9.0目录
$ mkdir /home/harbor-1.9.0 && tar zxvf /home/tools/harbor/harbor-offline-installer-v1.9.0.tgz -C /home/harbor-1.9.0
```

#### 四、修改[vi /home/harbor-1.9.0/harbor/harbor.yml]配置文件
```bash
hostname: server001                    # 修改为当前机器的IP或主机名
http:
  port: 7079                           # 绑定端口
harbor_admin_password: Jiang123        # admin用户的密码（注意：密码要包含大小写和数字）
data_volume: /data                     # 镜像存储目录
```

#### 六、部署harbor，访问地址：http://IP:PORT
```bash
$ cd /home/harbor-1.9.0/harbor         # 定位到Harbor解压目录
$ ./install.sh                         # 执行部署
```