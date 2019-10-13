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

#### 七、测试私有仓库推拉镜像（注意：私有仓库地址要在docker的信任地址里面，否则推拉镜像可能报错[如何配置docker信任私有仓库地址](https://github.com/firechiang/kubernetes-study/blob/master/docker/docs/docker-online-install.md#%E4%B8%89%E9%85%8D%E7%BD%AE-vi-etcdockerdaemonjson-%E6%8C%87%E5%AE%9Adocker%E5%90%AF%E5%8A%A8%E5%8F%82%E6%95%B0%E5%8F%AF%E4%BD%BF%E7%94%A8docker-info%E5%85%88%E6%9F%A5%E7%9C%8B%E9%BB%98%E8%AE%A4%E5%80%BC%E5%86%8D%E4%BF%AE%E6%94%B9%E5%BB%BA%E8%AE%AE%E4%BD%BF%E7%94%A8%E9%BB%98%E8%AE%A4%E5%80%BC%E6%B3%A8%E6%84%8F%E4%BF%AE%E6%94%B9%E8%BF%99%E4%B8%AA%E9%85%8D%E7%BD%AE%E9%9C%80%E8%A6%81%E5%85%88%E5%90%AF%E5%8A%A8docker)）
```bash
$ docker login server003:7079          # 登陆私有仓库，然后输入用户名和密码（注意：私有仓库地址要在docker信任地址里面）
    Username: admin
    Password: Harbor12345
    
# 打tag      镜像                私有仓库         私有仓库项目  完成后镜像名及版本
               |             |             |           |
$ docker tag openjdk:8-jre server003:7079/test-service/openjdk:9-jre   

# 推送镜像
$ docker push server003:7079/test-service/openjdk:9-jre

# 拉取镜像
$ docker pull server003:7079/test-service/openjdk:9-jre    
```