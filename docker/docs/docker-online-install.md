#### 一、安装Docker，[官网安装文档](https://docs.docker.com/install/linux/docker-ce/centos/)
```bash
$ yum remove -y docker* container-selinux                    # 清理原有版本
$ sudo yum install yum-utils device-mapper-persistent-data lvm2
$ sudo yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
$ sudo yum install docker-ce -y
$ yum list docker-ce.x86_64 --showduplicates | sort -r       # 查看Docker安装详情
```


#### 二、启动
```bash
$ docker -v                                                  # 查看Docker版本号
$ docker version                                             # 查看Docker版本详细信息

$ sudo systemctl start docker.service                        # 启动Docker
$ sudo systemctl restart docker.service                      # 重启Docker
$ sudo systemctl stop docker.service                         # 停止Docker
$ sudo systemctl status docker.service                       # 查看Docker状态

$ sudo systemctl enable docker.service                       # 设置开机启动Docker
$ sudo systemctl disable docker.service                      # 禁止开机启动Docker
```

#### 三、普通用户运行Docker
```bash
$ sudo groupadd docker                                       # 创建docker用户组（注意：这个一般在安装docker时就自动创建好了，可以使用命令：more /etc/group 查看是否存在）
$ sudo gpasswd -a ${USER} docker                             # 将当前用户添加到docker用户组
$ sudo service docker restart                                # 重启docker服务
$ sudo chmod a+rw /var/run/docker.sock                       # 给普通用户赋予执行docker命令的权限
```

#### 四、配置 [vi /etc/docker/daemon.json] 指定Docker启动参数，可使用docker info先查看默认值再修改，建议使用默认值（注意：修改这个配置需要先启动Docker）
```bash
# registry-mirrors=设置镜像地址（可以使用docker info命令查看，默认镜像地址）
# graph=设置docker数据目录：选择比较大的分区（我这里是根目录就不需要配置了，默认为/var/lib/docker）
# exec-opts=设置cgroup driver驱动（默认是cgroupfs，也可使用docker info命令查看，改成systemd的主要目的是与Kubernetes的Kubelet配置统一）
# insecure-registries 指定信任的私有仓库地址，可以使用http方式访问（注意：多个用逗号隔开，如果没有私有仓库，可以不配置该选项）
{
  "registry-mirrors": ["https://fy707np5.mirror.aliyuncs.com"],
  "graph": "/var/lib/docker",
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "insecure-registries": ["server001:80"]
}

$ systemctl daemon-reload                                    # 重启守护进程
$ sudo systemctl restart docker.service                      # 重启Docker
```
