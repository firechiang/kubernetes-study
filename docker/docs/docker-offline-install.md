#### 一、下载安装依赖包
```bash
$ wget -P /home/tools/docker http://mirror.centos.org/centos/7/os/x86_64/Packages/yum-utils-1.1.31-50.el7.noarch.rpm
$ wget -P /home/tools/docker http://mirror.centos.org/centos/7/os/x86_64/Packages/device-mapper-persistent-data-0.7.3-3.el7.x86_64.rpm
$ wget -P /home/tools/docker http://mirror.centos.org/centos/7/os/x86_64/Packages/lvm2-2.02.180-8.el7.x86_64.rpm
$ wget -P /home/tools/docker https://download.docker.com/linux/static/stable/x86_64/docker-19.03.1.tgz
```

#### 二、安装Docker，详情请查看[官方安装文档](https://docs.docker.com/install/linux/docker-ce/binaries/#install-static-binaries)
```bash
$ cd /home/tools/docker
$ yum localinstall *.rpm                      # 安装所有依赖包
$ tar -xvf docker-19.03.1.tgz                 # 解压Docker安装包到当前目录
$ sudo cp docker/* /usr/bin/                  # 拷贝Docker安装包到/usr/bin/目录下
```

#### 三、修改[vi /etc/systemd/system/docker.service]将Docker注册为Service
```bash
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target
 
[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
 
[Install]
WantedBy=multi-user.target
```

#### 四、为docker.service文件添加权限
```bash
$ chmod +x /etc/systemd/system/docker.service   # 放开权限
$ systemctl daemon-reload                       # 重新加载配置
```

#### 五、启动Docker
```bash
$ docker -v                                     # 查看Docker版本
$ systemctl start docker			            # 启动Docker
$ systemctl enable docker.service			    # 设置开机自启
$ systemctl status docker			            # 查看Docker状态
```
