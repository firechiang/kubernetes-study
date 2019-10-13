#### 一、下载安装依赖包，[官方安装文档](https://docs.docker.com/install/linux/docker-ce/binaries/#install-static-binaries)
```bash
$ wget -P /home/tools/docker http://mirror.centos.org/centos/7/os/x86_64/Packages/device-mapper-persistent-data-0.7.3-3.el7.x86_64.rpm
$ wget -P /home/tools/docker http://mirror.centos.org/centos/7/os/x86_64/Packages/lvm2-2.02.180-8.el7.x86_64.rpm

$ wget -P /home/tools/docker http://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-selinux-17.03.1.ce-1.el7.centos.noarch.rpm
$ wget -P /home/tools/docker http://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-17.03.1.ce-1.el7.centos.x86_64.rpm
$ wget -P /home/tools/docker http://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-debuginfo-17.03.1.ce-1.el7.centos.x86_64.rpm
```

#### 二、安装Docker
```bash
$ cd /home/tools/docker
$ yum remove -y docker* container-selinux                    # 清理原有版本
$ yum localinstall *.rpm                                     # 安装所有依赖包
```

#### 三、启动
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
