#### 以Centos7.x为例安装Docker，官网参照文档 https://docs.docker.com/install/linux/docker-ce/centos/
```bash
$ sudo yum install yum-utils device-mapper-persistent-data lvm2
$ sudo yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
$ sudo yum install docker-ce -y
$ yum list docker-ce.x86_64 --showduplicates | sort -r       # 查看Docker安装详情
$ docker -v                                                  # 查看Docker版本号
$ docker version                                             # 查看Docker版本详细信息
$ sudo systemctl start docker.service                        # 立即启动 docker服务
$ sudo systemctl enable docker.service                       # 设置开机启动docker服务
```