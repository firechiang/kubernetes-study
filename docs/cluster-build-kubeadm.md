#### 一、环境说明（注意：每台机器都要配置好hostname和host）
```bash
-----------|------------|------------|
           |   Master   |   Worker   | 
-----------|------------|------------|
server006  |     Y      |            |
-----------|------------|------------|
server007  |     Y      |            |
-----------|------------|------------|
server008  |            |     Y      |
-----------|------------|------------|
```

#### 二、安装依赖包（注意：集群中每个节点都要安装）
```bash
# 更新yum源
$ yum update                            
$ yum install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp
```

#### 三、关闭防火墙（生产不建议关闭）、swap，重置iptables（注意：集群中每个节点都要安装）
```bash
# 关闭防火墙
$ systemctl stop firewalld && systemctl disable firewalld

# 重置iptables
$ iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT

# 关闭swap
$ swapoff -a
$ sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

# 关闭selinux
$ setenforce 0

# 关闭dnsmasq(不关闭可能导致docker容器无法解析域名)
$ service dnsmasq stop && systemctl disable dnsmasq
```

#### 四、创建Kubernetes配置文件（注意：集群中每个节点都要创建）
```bash
$ cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
EOF

$ sysctl -p /etc/sysctl.d/kubernetes.conf                # 使配置文件生效（注意：这一步不能报错）
```

#### 五、配置Kubernetes Yum源地址，我们使用的是阿里云的源，可以科学上网的同学可以把"mirrors.aliyun.com"替换为"packages.cloud.google.com"官方源即可（注意：集群中每个节点都要配置）
```bash
$ cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

#### 六、安装必要工具，我们装的版本是1.14.0，也就是Kubernetes的版本（注意：集群中每个节点都要安装）
 - Kubeadm：部署集群用的命令
 - Kubelet：集群中每个节点都要运行的组件，负责管理pod、容器的生命周期
 - Kubectl：集群管理工具，可选，只要在控制集群的节点上安装即可
```bash
# 查看并找到想要安装的Kubernetes版本号
$ yum list kubeadm --showduplicates | sort -r  

# 安装Kubeadm和Kubelet以及Kubectl（我们装的版本是1.14.0，也就是Kubernetes的版本）
$ yum install -y kubeadm-1.14.0-0 kubelet-1.14.0-0 kubectl-1.14.0-0 --disableexcludes=kubernetes
```

#### 七、修改Kubelet的CGroup Driver驱动和Docker的保持一致，因为Kubelet的CGroup Driver默认为systemd。Docker的默认为cgroupfs。如果Docker的已经改了，那这里就不需要改了（注意：如果需要修改的话，集群中每个节点都要修改）
```bash
# 注意：如果这个文件报不存在的错误，可能是这个 /etc/systemd/system/kubelet.service.d/10-kubeadm.conf 目录
# 也可以使用 find / -name *kubeadm.conf 命令找到文件所在地址
$ sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
```

#### 八、创建[vi /home/kubeadm-config.yaml]使用Kubeadm搭建集群的配置文件（注意：集群中每个节点都要创建）
```bash
apiVersion: kubeadm.k8s.io/v1beta1
# 集群模式
kind: ClusterConfiguration
# Kubernetes版本
kubernetesVersion: v1.14.0
# API Server的服务地址（注意：如果有多个API Server就是Master节点，建议使用Keepalived抢占IP，以达到高可用）
controlPlaneEndpoint: "server006:6443"
networking:
    # pod的网段（就是容器内部的网段），16位的掩码（注意：这些都可以改，但不要和已使用的网段起冲突）
    podSubnet: "172.22.0.0/16"
# 指定镜像地址    
imageRepository: registry.aliyuncs.com/google_containers
```
#### 九、使用Kubeadm工具创建Kubernetes集群的主节点（注意：我们有多个主节点都要执行）
```bash
# --config是指定Kubeadm工具的配置文件（配置文件在上一步已经创建好了）
$ kubeadm init --config=/home/kubeadm-config.yaml --experimental-upload-certs
```


