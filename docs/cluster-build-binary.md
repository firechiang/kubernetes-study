#### 一、环境简要说明
 - Kubernetes集群以ETCD作为注册中心（注意：要先搭建好ETCD集群）
 - 集群中每个节点要预先[安装Docker](https://github.com/firechiang/kubernetes-study/tree/master/docker/docs/docker-online-install.md)而且还要配置好hostname和host）
 - [官方安装文档](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)，[本集群搭建参考文档](https://gitee.com/pa/kubernetes-ha-binary)
```bash
-----------|--------------------|------------|
           |  Master(ApiServer) |   Worker   |
-----------|--------------------|------------|
server006  |          Y         |            |
-----------|--------------------|------------|
server007  |          Y         |            |
-----------|--------------------|------------|
server008  |                    |     Y      |
-----------|--------------------|------------|
```

#### 二、关闭集群各个节点swap和selinux以及dnsmasq（注意：集群中每个节点都要执行）
```bash
# 关闭swap（注意：Kubernetes不支持swap（用硬盘补内存））
$ swapoff -a
$ sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

# 关闭selinux
$ setenforce 0

# 关闭dnsmasq(不关闭可能导致docker容器无法解析域名)
$ service dnsmasq stop && systemctl disable dnsmasq
```

#### 三、为集群中各个节点创建Kubernetes配置文件（注意：集群中每个节点都要创建）
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

# 使配置文件生效（注意：这一步不能报错）
$ sysctl -p /etc/sysctl.d/kubernetes.conf               
```

#### 四、安装CA证书工具cfssl（注意：随便找一台机器安装并生成CA证书，最后将证书拷贝到其它节点即可）
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

#### 五、生成CA根证书（注意：在装有cfssl工具的节点上执行生成CA根证书，其它节点要生成证书在该节点生成即可，然后再拷贝到集群的各个节点即可）
```bash
# 创建存放根证书目录
$ mkdir -p /home/cfssl/pki/kubernetes-cluster

# 创建config配置文件（注意：证书的过期时间是87600小时）
$ cat > /home/cfssl/pki/kubernetes-cluster/ca-config.json <<EOF
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
$ cat > /home/cfssl/pki/kubernetes-cluster/ca-csr.json <<EOF
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
$ cd /home/cfssl/pki/kubernetes-cluster/

# 生成证书和私钥
$ /home/cfssl/bin/cfssl gencert -initca ca-csr.json | /home/cfssl/bin/cfssljson -bare ca

# 生成完成后会有以下文件（我们最终想要的就是ca-key.pem和ca.pem，一个秘钥，一个证书）
$ ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem
```


#### 六、生成Api Server的证书（注意：在装有cfssl工具的节点上执行生成证书，最后将证书拷贝到其它节点即可）
```bash
# 创建并定位到存放Api Server的证书目录
$ mkdir -p /home/cfssl/pki/kubernetes-cluster/apiserver && cd /home/cfssl/pki/kubernetes-cluster/apiserver

# 创建Api Server的csr配置文件，注意修改IP和主机名（注意：创建时要删除注释，否则无法生成证书，会报invalid character '#' looking for beginning of value错误）
$ vi /home/cfssl/pki/kubernetes-cluster/apiserver/kubernetes-csr.json
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "server006",
    "server007",
    "server008",
    # 当前正在使用的Api Server节点的IP（注意：最好用Keepalived做高可用，然后配个虚拟ip或主机名放到这里）
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

# 生成证书、私钥（注意：\代表命令换行的意思）
$ /home/cfssl/bin/cfssl gencert                             \
  -ca=/home/cfssl/pki/kubernetes-cluster/ca.pem             \
  -ca-key=/home/cfssl/pki/kubernetes-cluster/ca-key.pem     \
  -config=/home/cfssl/pki/kubernetes-cluster/ca-config.json \
  -profile=kubernetes /home/cfssl/pki/kubernetes-cluster/apiserver/kubernetes-csr.json | /home/cfssl/bin/cfssljson -bare kubernetes
  
# 生成完成后会有以下文件（我们最终想要的就是kubernetes-key.pem和kubernetes.pem，一个秘钥，一个证书）
$ ls
kubernetes.csr  kubernetes-csr.json  kubernetes-key.pem  kubernetes.pem
```

#### 七、生成Kubectl的证书（注意：在装有cfssl工具的节点上执行生成证书，最后将证书拷贝到其它节点即可）
```bash
# 创建并定位到存放Kubectl的证书目录
$ mkdir -p /home/cfssl/pki/kubernetes-cluster/kubectl && cd /home/cfssl/pki/kubernetes-cluster/kubectl

# 创建Kubectl的csr配置文件
$ cat > /home/cfssl/pki/kubernetes-cluster/kubectl/admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "seven"
    }
  ]
}
EOF

# 生成证书、私钥（注意：\代表命令换行的意思）
$ /home/cfssl/bin/cfssl gencert -ca=/home/cfssl/pki/kubernetes-cluster/ca.pem \
  -ca-key=/home/cfssl/pki/kubernetes-cluster/ca-key.pem       \
  -config=/home/cfssl/pki/kubernetes-cluster/ca-config.json   \
  -profile=kubernetes /home/cfssl/pki/kubernetes-cluster/kubectl/admin-csr.json | /home/cfssl/bin/cfssljson -bare admin
```

#### 八、生成Controller Manager的证书（注意：在装有cfssl工具的节点上执行生成证书，最后将证书拷贝到其它节点即可）
```bash
# 创建并定位到存放Controller Manager的证书目录
$ mkdir -p /home/cfssl/pki/kubernetes-cluster/controller-manager && cd /home/cfssl/pki/kubernetes-cluster/controller-manager

# 创建Controller Manager的csr配置文件（注意：修改主节点的主机名）
$ cat > /home/cfssl/pki/kubernetes-cluster/controller-manager/controller-manager-csr.json <<EOF
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "server006",
      "server007",
      "server008"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "system:kube-controller-manager",
        "OU": "seven"
      }
    ]
}
EOF

# 生成证书、私钥（注意：\代表命令换行的意思）
$ /home/cfssl/bin/cfssl gencert -ca=/home/cfssl/pki/kubernetes-cluster/ca.pem \
  -ca-key=/home/cfssl/pki/kubernetes-cluster/ca-key.pem       \
  -config=/home/cfssl/pki/kubernetes-cluster/ca-config.json   \
  -profile=kubernetes /home/cfssl/pki/kubernetes-cluster/controller-manager/controller-manager-csr.json | /home/cfssl/bin/cfssljson -bare controller-manager
```


#### 九、生成Scheduler的证书（注意：在装有cfssl工具的节点上执行生成证书，最后将证书拷贝到其它节点即可）
```bash
# 创建并定位到存放Scheduler的证书目录
$ mkdir -p /home/cfssl/pki/kubernetes-cluster/scheduler && cd /home/cfssl/pki/kubernetes-cluster/scheduler

# 创建Scheduler的csr配置文件（注意：修改主节点的主机名）
$ cat > /home/cfssl/pki/kubernetes-cluster/scheduler/scheduler-csr.json <<EOF
{
    "CN": "system:kube-scheduler",
    "hosts": [
      "127.0.0.1",
      "server006",
      "server007",
      "server008"
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
        "O": "system:kube-scheduler",
        "OU": "seven"
      }
    ]
}
EOF

# 生成证书、私钥（注意：\代表命令换行的意思）
$ /home/cfssl/bin/cfssl gencert -ca=/home/cfssl/pki/kubernetes-cluster/ca.pem \
  -ca-key=/home/cfssl/pki/kubernetes-cluster/ca-key.pem       \
  -config=/home/cfssl/pki/kubernetes-cluster/ca-config.json   \
  -profile=kubernetes /home/cfssl/pki/kubernetes-cluster/scheduler/scheduler-csr.json | /home/cfssl/bin/cfssljson -bare kube-scheduler
```

#### 十、生成Kube Proxy的证书（注意：在装有cfssl工具的节点上执行生成证书，最后将证书拷贝到其它节点即可）
```bash
# 创建并定位到存放Kube Proxy的证书目录
$ mkdir -p /home/cfssl/pki/kubernetes-cluster/kube-proxy && cd /home/cfssl/pki/kubernetes-cluster/kube-proxy

# 创建Kube Proxy的csr配置文件
$ cat > /home/cfssl/pki/kubernetes-cluster/kube-proxy/kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
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
$ /home/cfssl/bin/cfssl gencert -ca=/home/cfssl/pki/kubernetes-cluster/ca.pem \
  -ca-key=/home/cfssl/pki/kubernetes-cluster/ca-key.pem       \
  -config=/home/cfssl/pki/kubernetes-cluster/ca-config.json   \
  -profile=kubernetes  /home/cfssl/pki/kubernetes-cluster/kube-proxy/kube-proxy-csr.json | /home/cfssl/bin/cfssljson -bare kube-proxy
```

#### 十一、分发证书到集群的各个节点
```bash
# 创建节点存放证书目录并将证书复制到该目录
$ mkdir -p /etc/kubernetes-pki-cluster && scp /home/cfssl/pki/kubernetes-cluster/* /etc/kubernetes-pki-cluster

# 将所有的证书分发到集群的各个节点
$ scp -r /etc/kubernetes-pki-cluster root@server007:/etc
$ scp -r /etc/kubernetes-pki-cluster root@server008:/etc
```

#### 十二、下载和分发主节点安装包（因要翻墙下载，所以百度云有备份），[官方详细下载地址](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.15.md)
```bash
# 下载主节点安装包
$ wget -P /home/tools/kubernetes/apiServer https://dl.k8s.io/v1.15.3/kubernetes-server-linux-amd64.tar.gz

# 下载从节点安装包
$ wget -P /home/tools/kubernetes/work https://dl.k8s.io/v1.15.3/kubernetes-node-linux-amd64.tar.gz

# 定位到主节点安装包目录
$ cd /home/tools/kubernetes/apiServer

# 解压主节点安装包并将里面的内容复制到/opt/kubernetes目录
$ tar -vxf kubernetes-server-linux-amd64.tar.gz && mkdir -p /opt/kubernetes-apiserver && scp -r ./kubernetes/* /opt/kubernetes-apiserver

# 分发Api Server安装包到集群的各个主节点（注意：是主节点）
$ scp -r /opt/kubernetes-apiserver root@server007:/opt
```

#### 十三、在集群的各个主节点上创建 [vi /etc/systemd/system/kube-apiserver.service] Api Service系统启动文件（注意：IP要修改成节点自己的，而且创建文件时，要删除注释，否则会报错）
```bash
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
ExecStart=/opt/kubernetes-apiserver/server/bin/kube-apiserver \
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --anonymous-auth=false \
  # 当前节点的IP（注意：修改成自己的IP，一定是IP，否则报错）
  --advertise-address=192.168.83.143 \
  --bind-address=0.0.0.0 \
  --insecure-port=0 \
  --authorization-mode=Node,RBAC \
  --runtime-config=api/all \
  --enable-bootstrap-token-auth \
  # Kubernetes服务ip网段（注意：这个一般不需要修改）
  --service-cluster-ip-range=10.254.0.0/16 \
  # NodePort的取值范围（注意：下面的这个范围一般也够用了，不需要修改）
  --service-node-port-range=8400-8900 \
  # Api Server相关证书地址
  --tls-cert-file=/etc/kubernetes-pki-apiserver/kubernetes.pem \
  --tls-private-key-file=/etc/kubernetes-pki-apiserver/kubernetes-key.pem \
  --client-ca-file=/etc/kubernetes-pki-apiserver/ca.pem \
  --kubelet-client-certificate=/etc/kubernetes-pki-apiserver/kubernetes.pem \
  --kubelet-client-key=/etc/kubernetes-pki-apiserver/kubernetes-key.pem \
  --service-account-key-file=/etc/kubernetes-pki-apiserver/ca-key.pem \
  # ETCD相关证书地址
  --etcd-cafile=/etc/kubernetes/pki/etcd/ca.pem \
  --etcd-certfile=/etc/kubernetes/pki/etcd/etcd.pem \
  --etcd-keyfile=/etc/kubernetes/pki/etcd/etcd-key.pem \
  # ETCD集群的地址
  --etcd-servers=https://server006:2379,https://server007:2379,https://server008:2379 \
  # 是否启用swagger-ui接口描述
  --enable-swagger-ui=true \
  --allow-privileged=true \
  --apiserver-count=3 \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/log/kube-apiserver-audit.log \
  --event-ttl=1h \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/var/log/kubernetes \
  --v=2
Restart=on-failure
RestartSec=5
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

#### 十四、启动和简单测试Api Server节点（注意：集群每个主节点都要执行）
```bash
$ sudo systemctl daemon-reload && systemctl start kube-apiserver   # 启动 Api Server
$ sudo systemctl daemon-reload && systemctl restart kube-apiserver # 重启 Api Server
$ sudo systemctl stop kube-apiserver                               # 停止 Api Server
$ sudo systemctl enable kube-apiserver                             # 开启开机启动（建议开启）
$ sudo systemctl disable kube-apiserver                            # 禁止开机启动

$ sudo service kube-apiserver status                               # 查看 Api Server 服务状态
$ journalctl -f -u kube-apiserver                                  # 查看 Api Server 日志
$ netstat -ntlp                                                    # 查看端口绑定情况

# 查看当前节点Api Server的健康状态，正常的话会放回ok（注意：不带证书访问的话会报没有权限错误）
$ curl -k                                                \
  --cert /etc/kubernetes-pki-apiserver/kubernetes.pem    \
  --key /etc/kubernetes-pki-apiserver/kubernetes-key.pem \
  https://127.0.0.1:6443/healthz
```
