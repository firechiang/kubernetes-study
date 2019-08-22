#### 一、环境说明，[官方安装文档](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)，[参考文档](https://gitee.com/pa/kubernetes-ha-binary)，（注意：集群中每个节点要预先[安装Docker](https://github.com/firechiang/kubernetes-study/tree/master/docker/docs/docker-online-install.md)而且还要配置好hostname和host）
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

#### 三、关闭防火墙（生产不建议关闭）、swap，重置iptables（注意：集群中每个节点都要设置）
```bash
# 关闭防火墙
$ systemctl stop firewalld && systemctl disable firewalld

# 重置iptables
$ iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT

# 关闭swap（注意：Kubernetes不支持swap（用硬盘补内存））
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

#### 五、安装CA证书工具cfssl和生成各个组件的CA证书（注意：随便找一台机器安装并生成CA证书，最后将证书拷贝到其它节点即可）
##### 5.1，安装CA证书工具cfssl
```bash
# 创建安装目录
$ mkdir -p /home/cfssl/bin

# 下载cfssl工具
$ wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O /home/cfssl/bin/cfssl
$ wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O /home/cfssl/bin/cfssljson

# 修改cfssl相关文件为可执行权限
$ chmod +x /home/cfssl/bin/cfssl /home/cfssl/bin/cfssljson

# 查看cfssl工具的版本
$ /home/cfssl/bin/cfssl version
```
##### 5.2，生成CA根证书
```bash
# 创建存放根证书目录
$ mkdir -p /home/cfssl/pki

# 创建config配置文件（注意：里面有过期时间等一些信息）
$ cat > /home/cfssl/pki/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF

# 创建csr配置文件
$ cat > /home/cfssl/pki/ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "seven"
    }
  ]
}
EOF

# 到存放根证书目录
$ cd /home/cfssl/pki/

# 生成证书和私钥
$ /home/cfssl/bin/cfssl gencert -initca ca-csr.json | /home/cfssl/bin/cfssljson -bare ca

# 生成完成后会有以下文件（我们最终想要的就是ca-key.pem和ca.pem，一个秘钥，一个证书）
$ ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem
```

##### 5.3，生成ETCD的证书
```bash
# 创建并定位到存放ETCD的证书目录
$ mkdir -p /home/cfssl/pki/etcd && cd /home/cfssl/pki/etcd

# 创建ETCD的csr配置文件（注意：要修改ETCD节点的主机名或IP）
$ cat > /home/cfssl/pki/etcd/etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "server006",
    "server007"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "seven"
    }
  ]
}
EOF

# 生成证书、私钥（注意：\代表命令换行的意思）
$ /home/cfssl/bin/cfssl gencert           \
  -ca=/home/cfssl/pki/ca.pem              \
  -ca-key=/home/cfssl/pki/ca-key.pem      \
  -config=/home/cfssl/pki/ca-config.json  \
  -profile=kubernetes /home/cfssl/pki/etcd/etcd-csr.json | /home/cfssl/bin/cfssljson -bare etcd
  
# 生成完成后会有以下文件（我们最终想要的就是etcd-key.pem和etcd.pem，一个秘钥，一个证书）
$ ls
etcd.csr  etcd-csr.json  etcd-key.pem  etcd.pem  
```

##### 5.4，生成Api Server的证书
```bash
# 创建并定位到存放Api Server的证书目录
$ mkdir -p /home/cfssl/pki/apiserver && cd /home/cfssl/pki/apiserver

# 创建Api Server的csr配置文件（注意：创建时要删除注释，否则无法生成证书，会报invalid character '#' looking for beginning of value错误）
$ cat > /home/cfssl/pki/apiserver/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    # Api Server节点主机名或IP
    "server006",
    # Api Server节点主机名或IP
    "server007",
    # 当前正在使用的Api Server节点的IP（注意：最好用Keepalived做高可用，然后配个虚拟ip放到这里）
    "192.168.83.143",
    # kubernetes的默认服务ip，一般是cidr的第一个（注意：这个一般不需要修改）
    "10.254.0.1",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "seven"
    }
  ]
}
EOF


# 生成证书、私钥（注意：kubernetes-csr.json 配置文件里面的注释要删除掉，否则会报错，\代表命令换行的意思）
$ /home/cfssl/bin/cfssl gencert           \
  -ca=/home/cfssl/pki/ca.pem              \
  -ca-key=/home/cfssl/pki/ca-key.pem      \
  -config=/home/cfssl/pki/ca-config.json  \
  -profile=kubernetes /home/cfssl/pki/apiserver/kubernetes-csr.json | /home/cfssl/bin/cfssljson -bare kubernetes
  
# 生成完成后会有以下文件（我们最终想要的就是kubernetes-key.pem和kubernetes.pem，一个秘钥，一个证书）
$ ls
kubernetes.csr  kubernetes-csr.json  kubernetes-key.pem  kubernetes.pem   
```

##### 5.5，分发证书到集群的所有主节点（注意：是主节点）
```bash
# 为每个主节点上创建存放证书的目录（注意：这个命令所有的主节点都要执行）
$ mkdir -p /etc/kubernetes/pki

# 分发CA根证书到每个主节点
$ scp /home/cfssl/pki/*.pem root@server006:/etc/kubernetes/pki/
$ scp /home/cfssl/pki/*.pem root@server007:/etc/kubernetes/pki/

# 分发ETCD证书到每个主节点
$ scp /home/cfssl/pki/etcd/etcd*.pem root@server006:/etc/kubernetes/pki/
$ scp /home/cfssl/pki/etcd/etcd*.pem root@server007:/etc/kubernetes/pki/

# 分发API Server证书到每个主节点
$ scp /home/cfssl/pki/apiserver/kubernetes*.pem root@server006:/etc/kubernetes/pki/
$ scp /home/cfssl/pki/apiserver/kubernetes*.pem root@server007:/etc/kubernetes/pki/
```

#### 六、部署ETCD集群，在Kubernetes集群的Master节点上部署ETCD节点（注意：以下操作在集群当中，随便找一台主节点操作即可。还有ETCD和ZK的算法相同，建议ETCD集群的节点数是大于等3的基数个）
##### 6.1，下载和安装ETCD以及分发安装包到集群的各个主节点
```bash
# 创建ETCD的安装目录和数据存储目录（注意：这个命令所有的主节点都要执行）
$ mkdir -p /opt/kubernetes/bin/etcd && mkdir -p /var/lib/etcd

# 下载安装包
$ wget -P /home/tools/kubernetes https://github.com/etcd-io/etcd/releases/download/v3.3.15/etcd-v3.3.15-linux-amd64.tar.gz

# 定位到下载目录
$ cd /home/tools/kubernetes

# 解压安装包并将里面的内容复制到/opt/kubernetes/bin/etcd目录
$ tar -zxvf etcd-v3.3.15-linux-amd64.tar.gz && scp -r ./etcd-v3.3.15-linux-amd64/* /opt/kubernetes/bin/etcd


# 分发ETCD安装包到其它主节点
$ scp -r /opt/kubernetes/bin/etcd root@server006:/opt/kubernetes/bin
$ scp -r /opt/kubernetes/bin/etcd root@server007:/opt/kubernetes/bin
```

##### 6.2，在各个主节点上创建ETCD Service系统启动文件（注意：创建文件时，要删除注释，否则会报错）
```bash
# 创建server006的ETCD Service系统启动文件，内容如下（注意：该命令在主节点server006上执行，创建文件时，要删除注释，否则会报错）
$ vi /etc/systemd/system/etcd.service 
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
# ETCD数据存储地址
WorkingDirectory=/var/lib/etcd/
# ETCD启动文件所在地址
ExecStart=/opt/kubernetes/bin/etcd/etcd \
  # ETCD数据存储地址
  --data-dir=/var/lib/etcd \
  --name=server006 \
  --cert-file=/etc/kubernetes/pki/etcd.pem \
  --key-file=/etc/kubernetes/pki/etcd-key.pem \
  --trusted-ca-file=/etc/kubernetes/pki/ca.pem \
  --peer-cert-file=/etc/kubernetes/pki/etcd.pem \
  --peer-key-file=/etc/kubernetes/pki/etcd-key.pem \
  --peer-trusted-ca-file=/etc/kubernetes/pki/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  # 当前节点的IP（注意：一定是IP，否则报错，每个节点需要不一样）
  --listen-peer-urls=https://192.168.83.143:2380 \
  # 当前节点的IP（注意：一定是IP，否则报错，每个节点需要不一样）
  --initial-advertise-peer-urls=https://192.168.83.143:2380 \
  # 当前节点的IP（注意：一定是IP，否则报错，每个节点需要不一样）
  --listen-client-urls=https://192.168.83.143:2379,http://127.0.0.1:2379 \
  # 当前节点的IP（注意：一定是IP，否则报错，每个节点需要不一样）
  --advertise-client-urls=https://192.168.83.143:2379 \
  --initial-cluster-token=etcd-cluster-0 \
  # ETCD集群所有节点的信息
  --initial-cluster=server006=https://server006:2380,server007=https://server007:2380 \
  --initial-cluster-state=new
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

# 创建server007的ETCD Service系统启动文件，内容如下（注意：该命令在主节点server007上执行，创建文件时，要删除注释，否则会报错）
$ vi /etc/systemd/system/etcd.service 
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
# ETCD数据存储地址
WorkingDirectory=/var/lib/etcd/
# ETCD启动文件所在地址
ExecStart=/opt/kubernetes/bin/etcd/etcd \
  # ETCD数据存储地址
  --data-dir=/var/lib/etcd \
  --name=server007 \
  --cert-file=/etc/kubernetes/pki/etcd.pem \
  --key-file=/etc/kubernetes/pki/etcd-key.pem \
  --trusted-ca-file=/etc/kubernetes/pki/ca.pem \
  --peer-cert-file=/etc/kubernetes/pki/etcd.pem \
  --peer-key-file=/etc/kubernetes/pki/etcd-key.pem \
  --peer-trusted-ca-file=/etc/kubernetes/pki/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  # 当前节点的IP（注意：一定是IP，否则报错，每个节点需要不一样）
  --listen-peer-urls=https://192.168.83.144:2380 \
  # 当前节点的IP（注意：一定是IP，否则报错，每个节点需要不一样）
  --initial-advertise-peer-urls=https://192.168.83.144:2380 \
  # 当前节点的IP（注意：一定是IP，否则报错，每个节点需要不一样）
  --listen-client-urls=https://192.168.83.144:2379,http://127.0.0.1:2379 \
  # 当前节点的IP（注意：一定是IP，否则报错，每个节点需要不一样）
  --advertise-client-urls=https://192.168.83.144:2379 \
  --initial-cluster-token=etcd-cluster-0 \
  # ETCD集群所有节点的信息
  --initial-cluster=server006=https://server006:2380,server007=https://server007:2380 \
  --initial-cluster-state=new
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

##### 6.3，启动ETCD的各个节点（注意：以下命令所有的主节点都要执行）
```bash
$ sudo systemctl start etcd       # 启动ETCD
$ sudo systemctl stop etcd        # 停止ETCD
$ sudo systemctl restart etcd     # 重启ETCD
$ sudo systemctl enable etcd      # 开启开机启动
$ sudo systemctl daemon-reload    # 重启守护进程
```

#### 五、下载和安装以及分发安装包（因要翻墙下载，所以百度云有备份），[官方详细下载地址](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.15.md)
```bash
# 下载主节点安装包
$ wget -P /home/tools/kubernetes https://dl.k8s.io/v1.15.3/kubernetes-server-linux-amd64.tar.gz
# 下载从节点安装包
$ wget -P /home/tools/kubernetes https://dl.k8s.io/v1.15.3/kubernetes-node-linux-amd64.tar.gz

$ cd /home/tools/kubernetes
# 将主节点安装包解压到上层目录
$ tar -zxvf kubernetes-server-linux-amd64.tar.gz -C ../
# 分发安装包到其它节点
$ scp -r /home/tools/kubernetes root@server007:/home/tools
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

#### 七、启动 Kubelet（注意：因为还未配置集群，启动Kubelet回报错，所以可以不手动启动 Kubelet，只需要开启开机启动 Kubelet即可，它会自动启动）
```bash
$ systemctl start kubelet.service                          # 启动 Kubelet
$ systemctl restart kubelet.service                        # 重动 Kubelet
$ systemctl stop kubelet.service                           # 停止 Kubelet
$ systemctl status kubelet.service                         # 查看 Kubelet状态

$ systemctl enable kubelet.service                         # 启用开机启动 Kubelet（注意：建议启用）
$ systemctl disable kubelet.service                        # 禁用开机启动 Kubelet
```

#### 八、修改 [vi /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf] 指定Kubelet的CGroup Driver驱动和Docker的保持一致，因为Kubelet的CGroup Driver默认为systemd。Docker的默认为cgroupfs。建议使用cgroupfs，因为在搭建的过程中使用systemd驱动，日志文件总是不停的有错误信息（说明：如果/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf配置文件没有。可使用 find / -name *kubeadm.conf 命令找到10-kubeadm.conf文件所在地址。注意：集群中每个节点都要修改）
```bash
# 新增这一行
Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=cgroupfs"
# 修改这一行，好像是最后一行，在最后面添加 $KUBELET_CGROUP_ARGS（就是我们上面定义的那个变量）
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS $KUBELET_CGROUP_ARGS

$ systemctl daemon-reload                                  # 重启守护进程
$ systemctl restart kubelet.service                        # 重启 Kubelet
```

#### 九、创建 [vi /home/kubeadm-config.yaml] 使用Kubeadm搭建集群的配置文件（注意：集群中每个节点都要创建）
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
#### 十、使用Kubeadm工具创建Kubernetes集群的第一个主节点（注意：要在我们上面的那个配置文件里面配置的那台API Server上安装）
##### 10.1，创建首个主节点（注意：kubeadm init命令执行完成以后会打印出新增节点加入集群的命令，切记要将这两个命令保存起来，具体命令看下面）
```bash
# --config是指定Kubeadm工具的配置文件（配置文件在上一步已经创建好了）
$ kubeadm init --config=/home/kubeadm-config.yaml --experimental-upload-certs

---------------------------kubeadm init命令打印的信息 statr----------------------------------------------------

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:
# 注意：这个命令要保存起来，如果要添加其它主节点到集群只需要拿着这个命令去那台机器上执行一下即可（前提是那台机器已经安装有Kubeadm工具和Docker）
  kubeadm join server006:6443 --token 066swh.oei8kdj0ax4z6h07 \
    --discovery-token-ca-cert-hash sha256:7cffb69278a9c7c1555695dd6427a20e8bdd93530bc3c8e683b8e842caeb8ea6 \
    --experimental-control-plane --certificate-key 1bacb184556cf573646d80f5c3b55fbce56a4f07e82bf42c511ef89e1de2eb61

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use 
"kubeadm init phase upload-certs --experimental-upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

# 注意：这个命令要保存起来，如果要添加从节点到集群只需要拿着这个命令去那台机器上执行一下即可（前提是那台机器已经安装有Kubeadm工具和Docker）
kubeadm join server006:6443 --token 066swh.oei8kdj0ax4z6h07 \
    --discovery-token-ca-cert-hash sha256:7cffb69278a9c7c1555695dd6427a20e8bdd93530bc3c8e683b8e842caeb8ea6
    
---------------------------kubeadm init命令打印的信息 end----------------------------------------------------    

# 配置节点（注意：以下的配置步骤，在上面的命令执行完成以后会有提示，要根据提示来做，一般是在Your Kubernetes control-plane has initialized successfully! 下面）
# 创建文件夹
$ mkdir -p $HOME/.kube     

# 拷贝配置文件到$HOME/.kube目录（注意：这个配置文件包含集群的信息和API Server的访问地址）
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config 

# 给配置文件赋予权限
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config          

# 获取当前pod的所有命名空间
# 查看节点是否搭建成功（注意：除了coredns是Pending状态，其它的都应该是Running状态。也可使用netstat -ntlp查看各个服务是否都起起来了）
$ kubectl get pods --all-namespaces                        
NAMESPACE     NAME                                READY   STATUS    RESTARTS   AGE
kube-system   coredns-8686dcc4fd-pgzmx            0/1     Pending   0          29m
kube-system   coredns-8686dcc4fd-wf4j7            0/1     Pending   0          29m
kube-system   etcd-server006                      1/1     Running   0          28m
kube-system   kube-apiserver-server006            1/1     Running   0          28m
kube-system   kube-controller-manager-server006   1/1     Running   0          28m
kube-system   kube-proxy-96jk7                    1/1     Running   0          29m
kube-system   kube-scheduler-server006            1/1     Running   0          28m

# 请求一下当前API Server的健康检查地址看看是否正常（注意：正常的话会返回ok，-k表示使用https）
$ curl -k https://localhost:6443/healthz
```

##### 10.2，在首个主节点上部署网络插件 Calico，[官方安装文档](https://docs.projectcalico.org/v3.8/getting-started/kubernetes/installation/calico#installing-with-the-kubernetes-api-datastoremore-than-50-nodes)，（注意：Calico只需要在首个主节点上部署，其它节点会自动部署）
```bash
# 创建存放Calico安装的配置文件目录
$ mkdir -p /etc/kubernetes/addons                          
$ cd /etc/kubernetes/addons

# 从官方下载Calico安装的配置文件
$ curl https://docs.projectcalico.org/v3.8/manifests/calico-typha.yaml -O

# 修改pod网段，我们上面的配置文件里面使用的是：172.22.0.0/16，所以要修改成它
$ POD_CIDR="172.22.0.0/16" && sed -i -e "s?192.168.0.0/16?$POD_CIDR?g" calico-typha.yaml

# 部署Calico（注意：可以修改calico-typha.yaml文件里面的replicas属性来指定Calico的部署副本数（默认是1，就是同时部署2个Calico），-f是指定配置文件）
$ kubectl apply -f calico-typha.yaml

# 查看pod的状态看看calico是否部署成功（注意：部署成功后，除了calico-typha容器是Pending状态以外，其它所有的容器都会处于Running（运行）状态）
$ kubectl get pods -n kube-system
NAME                                      READY   STATUS    RESTARTS   AGE
calico-kube-controllers-f9dbcb664-7cd6p   1/1     Running   0          77s
calico-node-xclk2                         0/1     Running   0          77s
calico-typha-649d9968df-2zrtq             0/1     Pending   0          78s
coredns-8686dcc4fd-66pr6                  1/1     Running   0          6m37s
coredns-8686dcc4fd-9x74w                  1/1     Running   0          6m37s
etcd-server006                            1/1     Running   0          5m30s
kube-apiserver-server006                  1/1     Running   0          5m54s
kube-controller-manager-server006         1/1     Running   0          5m42s
kube-proxy-rdwp4                          1/1     Running   0          6m37s
kube-scheduler-server006                  1/1     Running   0          5m53s

# 查看calico-typha-649d9968df-2zrtq运行的详细信息
# 因为calico-typha-649d9968df-2zrtq运行处于Pending状态，所以查看一下其详细信息（里面有没有跑起来的原因，一般在详细信息的最下面）
# 如果原因是：default-scheduler  0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate
# 表示我们没有Work节点（从节点），集群至少有一个Work节点，calico-typha才能跑起来（因为我们上面配置了Calico的部署副本数是1）
$ kubectl describe pods -n kube-system calico-typha-649d9968df-2zrtq(容器运行的名字可能不一样，注意修改)
```

#### 十一、添加其它主节点到集群（注意：当前机器要安装有Kubeadm工具和Docker以及/home/kubeadm-config.yaml配置文件（上面有配置文件的创建方法））
```bash
# 加入集群（注意：这个命令是第一个主节点搭建好以后打印出来的，上面有说明）
$ kubeadm join server006:6443 --token 066swh.oei8kdj0ax4z6h07 \
                              --discovery-token-ca-cert-hash sha256:7cffb69278a9c7c1555695dd6427a20e8bdd93530bc3c8e683b8e842caeb8ea6 \
                              --experimental-control-plane --certificate-key 1bacb184556cf573646d80f5c3b55fbce56a4f07e82bf42c511ef89e1de2eb61
                              
# 配置节点（注意：以下的配置步骤，在上面的命令执行完成以后会有提示，要根据提示来做，一般是在To start administering your cluster from this node, you need to run the following as a regular user 下面）
# 创建文件夹
$ mkdir -p $HOME/.kube

# 拷贝配置文件到$HOME/.kube目录（注意：这个配置文件包含集群的信息和API Server的访问地址）                                     
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config 

# 给配置文件赋予权限  
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config                                      
  
# 查看所有节点信息（注意：在主节点上执行（只要是主节点就是行），如果正常的话都是Ready状态）                       
$ kubectl get nodes	
NAME        STATUS   ROLES    AGE    VERSION
server006   Ready    master   34m     v1.14.0
server007   Ready    master   8m15s   v1.14.0
```

#### 十二、添加从节点到集群（注意：当前机器要安装有Kubeadm工具和Docker以及/home/kubeadm-config.yaml配置文件（上面有配置文件的创建方法））
```bash
# 加入集群（注意：这个命令是第一个主节点搭建好以后打印出来的，上面有说明）
$ kubeadm join server006:6443 --token 066swh.oei8kdj0ax4z6h07 \
    --discovery-token-ca-cert-hash sha256:7cffb69278a9c7c1555695dd6427a20e8bdd93530bc3c8e683b8e842caeb8ea6
                              
# 配置节点（注意：以下的配置步骤，在上面的命令执行完成以后会有提示，要根据提示来做，一般是在To start administering your cluster from this node, you need to run the following as a regular user 下面）
# 创建文件夹
$ mkdir -p $HOME/.kube                                   

# 拷贝配置文件到$HOME/.kube目录（注意：这个配置文件包含集群的信息和API Server的访问地址）  
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config 

# 给配置文件赋予权限
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config                                        
  
# 查看所有节点信息（注意：在主节点上执行（只要是主节点就是行），如果正常的话都是Ready状态）                            
$ kubectl get nodes	
NAME        STATUS   ROLES    AGE    VERSION
server006   Ready    master   45m    v1.14.0
server007   Ready    master   19m    v1.14.0
server008   Ready    <none>   109s   v1.14.0

# 查看pod里所有容器的状态，看看Calico是否正常了（正常的话都是Running状态）（注意：该命令须在主节点上执行）
# 开始集群里面没有从节点，所以calico-typha跑不起来处于Pending状态，现在有从节点了应该是Running（运行）状态
$ kubectl get pods -n kube-system
NAME                                      READY   STATUS    RESTARTS   AGE
calico-kube-controllers-f9dbcb664-7cd6p   1/1     Running   0          45m
calico-node-lf497                         1/1     Running   0          6m57s
calico-node-qx4zk                         1/1     Running   0          24m
calico-node-xclk2                         1/1     Running   0          45m
calico-typha-649d9968df-2zrtq             1/1     Running   0          45m
coredns-8686dcc4fd-66pr6                  1/1     Running   0          50m
coredns-8686dcc4fd-9x74w                  1/1     Running   0          50m
etcd-server006                            1/1     Running   0          49m
etcd-server007                            1/1     Running   0          24m
kube-apiserver-server006                  1/1     Running   0          49m
kube-apiserver-server007                  1/1     Running   0          24m
kube-controller-manager-server006         1/1     Running   1          49m
kube-controller-manager-server007         1/1     Running   0          24m
kube-proxy-cvw55                          1/1     Running   0          6m57s
kube-proxy-qf4pk                          1/1     Running   0          24m
kube-proxy-rdwp4                          1/1     Running   0          50m
kube-scheduler-server006                  1/1     Running   1          49m
kube-scheduler-server007                  1/1     Running   0          24m

# 到各个节点上执行,看看日志里面有没有什么问题
$ journalctl -f
```

