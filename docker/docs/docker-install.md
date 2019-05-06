#### 以Centos7.6(Linux 3.10内核) 为例安装Docker，Centos之前版本请参照官网安装: https://docs.docker.com/install/linux/docker-ce/centos/
```bash
$ sudo yum install -y yum-utils
$ sudo yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
$ sudo yum install docker-ce -y
$ sudo systemctl start docker.service                        # 立即启动 docker服务
$ sudo systemctl enable docker.service                       # 设置开机启动docker服务
```