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
$ swapoff -a && sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

# 关闭selinux
$ setenforce 0 && sed -i "/^SELINUX/s/enforcing/disabled/" /etc/selinux/config

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

# 创建Api Server的csr配置文件，注意修改Api Server节点的IP和主机名（注意：创建时要删除注释，否则无法生成证书，会报invalid character '#' looking for beginning of value错误）
$ vi /home/cfssl/pki/kubernetes-cluster/apiserver/kubernetes-csr.json
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "server006",
    "server007",
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
  
# 生成完成后会有以下文件（我们最终想要的就是admin-key.pem和admin.pem，一个秘钥，一个证书）
$ ls
admin.csr  admin-csr.json  admin-key.pem  admin.pem
```

#### 八、生成Controller Manager的证书（注意：在装有cfssl工具的节点上执行生成证书，最后将证书拷贝到其它节点即可）
```bash
# 创建并定位到存放Controller Manager的证书目录
$ mkdir -p /home/cfssl/pki/kubernetes-cluster/controller-manager && cd /home/cfssl/pki/kubernetes-cluster/controller-manager

# 创建Controller Manager的csr配置文件（注意：修改Api Server节点的主机名）
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
      "server007"
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
  
# 生成完成后会有以下文件（我们最终想要的就是controller-manager-key.pem和controller-manager.pem，一个秘钥，一个证书）
$ ls
controller-manager.csr  controller-manager-csr.json  controller-manager-key.pem  controller-manager.pem
```


#### 九、生成Scheduler的证书（注意：在装有cfssl工具的节点上执行生成证书，最后将证书拷贝到其它节点即可）
```bash
# 创建并定位到存放Scheduler的证书目录
$ mkdir -p /home/cfssl/pki/kubernetes-cluster/scheduler && cd /home/cfssl/pki/kubernetes-cluster/scheduler

# 创建Scheduler的csr配置文件（注意：修改Api Server节点的主机名）
$ cat > /home/cfssl/pki/kubernetes-cluster/scheduler/scheduler-csr.json <<EOF
{
    "CN": "system:kube-scheduler",
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

# 生成完成后会有以下文件（我们最终想要的就是kube-scheduler-key.pem和kube-scheduler.pem，一个秘钥，一个证书）
$ ls
kube-scheduler.csr  kube-scheduler-key.pem  kube-scheduler.pem  scheduler-csr.json
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

# 生成完成后会有以下文件（我们最终想要的就是kube-proxy-key.pem和kube-proxy.pem，一个秘钥，一个证书）
$ ls
kube-proxy.csr  kube-proxy-csr.json  kube-proxy-key.pem  kube-proxy.pem
```

#### 十一、分发证书到集群的所有节点
```bash
# 创建节点存放证书目录并将证书复制到该目录
$ mkdir -p /etc/kubernetes-pki-cluster && scp -r /home/cfssl/pki/kubernetes-cluster/* /etc/kubernetes-pki-cluster

# 将所有的证书分发到集群的各个节点
$ scp -r /etc/kubernetes-pki-cluster root@server007:/etc
$ scp -r /etc/kubernetes-pki-cluster root@server008:/etc
```

#### 十二、下载和分发主节点安装包（因要翻墙下载，所以百度云有备份），[官方详细下载地址](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.15.md)
```bash
# 下载主节点安装包
$ wget -P /home/tools/kubernetes/apiServer https://dl.k8s.io/v1.15.3/kubernetes-server-linux-amd64.tar.gz

# 定位到主节点安装包目录
$ cd /home/tools/kubernetes/apiServer

# 解压主节点安装包并将里面的内容复制到/opt/kubernetes目录
$ tar -vxf kubernetes-server-linux-amd64.tar.gz && mkdir -p /opt/kubernetes-apiserver && scp -r ./kubernetes/* /opt/kubernetes-apiserver

# 分发Api Server安装包到集群的各个主节点（注意：是主节点）
$ scp -r /opt/kubernetes-apiserver root@server007:/opt
```

#### 十三、在集群的每个主节点上创建 [vi /etc/systemd/system/kube-apiserver.service] Api Service系统启动文件（注意：IP要修改成节点自己的，而且创建文件时，要删除注释，否则会报错），[kube-apiserver命令官方使用说明](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
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
  --tls-cert-file=/etc/kubernetes-pki-cluster/apiserver/kubernetes.pem \
  --tls-private-key-file=/etc/kubernetes-pki-cluster/apiserver/kubernetes-key.pem \
  --client-ca-file=/etc/kubernetes-pki-cluster/ca.pem \
  --kubelet-client-certificate=/etc/kubernetes-pki-cluster/apiserver/kubernetes.pem \
  --kubelet-client-key=/etc/kubernetes-pki-cluster/apiserver/kubernetes-key.pem \
  --service-account-key-file=/etc/kubernetes-pki-cluster/ca-key.pem \
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
  # 日志文件目录（注意：这个配置目录好像没用）
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
$ curl -k                                                        \
  --cert /etc/kubernetes-pki-cluster/apiserver/kubernetes.pem    \
  --key /etc/kubernetes-pki-cluster/apiserver/kubernetes-key.pem \
  https://127.0.0.1:6443/healthz
```

#### 十五、在主节点上部署Kubectl工具，因为使用该命令时，它默认会读取 ~/.kube/config配置文件里面Api Server的地址、证书、用户名等信息。所以下面的命令只是创建和配置 ~/.kube/config文件而已（注意：集群每个主节点都要执行），[kubectl命令官方使用说明](https://kubernetes.io/docs/reference/kubectl/kubectl/)
```bash
# 创建并定位到存储Kubectl工具的配置文件的目录
$ mkdir -p ~/.kube && cd ~/.kube

# 设置Api Server地址（注意：修改成当前节点的地址。这个命令只是往当前目录下的kube.config文件里面写了一些配置信息）
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes-pki-cluster/ca.pem                 \
  --embed-certs=true                                                         \
  --server=https://server007:6443                                            \
  --kubeconfig=config
  
# 设置证书相关配置（注意：这个命令只是往当前目录下的config文件里面写了一些配置信息）
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-credentials admin  \
  --client-certificate=/etc/kubernetes-pki-cluster/kubectl/admin.pem         \
  --client-key=/etc/kubernetes-pki-cluster/kubectl/admin-key.pem             \
  --embed-certs=true                                                         \
  --kubeconfig=config  
  
# 设置上下文配置（注意：这个命令只是往当前目录下的config文件里面写了一些配置信息）
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-context kubernetes \
  --cluster=kubernetes                                                       \
  --user=admin                                                               \
  --kubeconfig=config
  
# 设置默认上下文配置（注意：这个命令只是往当前目录下的config文件里面写了一些配置信息）
$ /opt/kubernetes-apiserver/server/bin/kubectl config use-context kubernetes --kubeconfig=config

# 授予kubernetes证书访问 kubelet API 的权限
# 因为在在执行 kubectl exec、run、logs 等命令时，apiserver 会转发到 kubelet。而kubelet里面定义了 RBAC规则，所以要授权 apiserver 调用 kubelet API的权限
$ /opt/kubernetes-apiserver/server/bin/kubectl create clusterrolebinding kube-apiserver:kubelet-apis \
  --clusterrole=system:kubelet-api-admin                                                             \
  --user kubernetes
  
# 测试Kubectl命令是否部署成功
# 查看Api Server状态信息
$ /opt/kubernetes-apiserver/server/bin/kubectl cluster-info
Kubernetes master is running at https://server007:6443

# 查看所有pod，service，deployment等信息
$ /opt/kubernetes-apiserver/server/bin/kubectl get all --all-namespaces
NAMESPACE   NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
default     service/kubernetes   ClusterIP   10.254.0.1   <none>        443/TCP   15h

# 获取所有组件的健康状态（注意：scheduler和controller-manager因为还没有部署所以是不健康的）
$ /opt/kubernetes-apiserver/server/bin/kubectl get componentstatuses  
NAME                 STATUS      MESSAGE                                  ERROR    
scheduler            Unhealthy   Get http://127.0.0.1:10251/healthz: dial tcp 127.0.0.1:10251: connect: connection refused   
controller-manager   Unhealthy   Get http://127.0.0.1:10252/healthz: dial tcp 127.0.0.1:10252: connect: connection refused   
etcd-2               Healthy     {"health":"true"}                                                                           
etcd-0               Healthy     {"health":"true"}                                                                           
etcd-1               Healthy     {"health":"true"}
```

#### 十六、为每个Api Server节点（Master节点）的Controller-Manager创建配置文件（注意：修改成当前节点的IP或主机名，还有每个Api Server节点（Master节点）都要执行）
 - Controller-Manager启动后将通过竞争选举机制产生一个 leader 节点，其它节点为阻塞状态。当 leader 节点不可用后，剩余节点将再次进行选举产生新的 leader 节点，从而保证服务的可用性
 - 说明：这个和 HDFS 集群的 NameNode 高可用相似
```bash
# 创建并进入配置文件目录
$ mkdir -p /opt/kubernetes-apiserver/config && cd /opt/kubernetes-apiserver/config

# 创建配置文件（注意：修改成当前节点的地址）
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes-pki-cluster/ca.pem                 \
  --embed-certs=true                                                         \
  --server=https://server006:6443                                            \
  --kubeconfig=controller-manager.kubeconfig
  
# 设置证书相关配置  
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=/etc/kubernetes-pki-cluster/controller-manager/controller-manager.pem         \
  --client-key=/etc/kubernetes-pki-cluster/controller-manager/controller-manager-key.pem             \
  --embed-certs=true                                                                                 \
  --kubeconfig=controller-manager.kubeconfig 
  
# 设置上下文配置  
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-context system:kube-controller-manager \
  --cluster=kubernetes                                                                           \
  --user=system:kube-controller-manager                                                          \
  --kubeconfig=controller-manager.kubeconfig 
  
# 设置默认上下文配置  
$ /opt/kubernetes-apiserver/server/bin/kubectl config use-context system:kube-controller-manager \
  --kubeconfig=controller-manager.kubeconfig  
```

#### 十七、[vi /etc/systemd/system/kube-controller-manager.service]为每个Api Server节点（Master节点）的Controller-Manager创建系统Service启动文件（注意：创建时要删除注释，否则会报错。还有每个Api Server节点（Master节点）都要创建），[kube-controller-manager命令官方使用说明](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/)
```bash
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/opt/kubernetes-apiserver/server/bin/kube-controller-manager \
  # 绑定 http的端口（注意：因为健康检查使用的是http的方式，所以绑定http的端口，0表示不绑定http的端口）
  --port=10252 \
  # 绑定 https的端口（注意：0表示不绑定https的端口）
  --secure-port=0 \
  --bind-address=127.0.0.1 \
  # Controller-Manager配置文件地址
  --kubeconfig=/opt/kubernetes-apiserver/config/controller-manager.kubeconfig \
  --service-cluster-ip-range=10.254.0.0/16 \
  --cluster-name=kubernetes \
  --allocate-node-cidrs=true \
  --cluster-cidr=172.22.0.0/16 \
  # 指定 TLS Bootstrap 证书的有效期
  --experimental-cluster-signing-duration=8760h \
  # CA相关证书地址
  --root-ca-file=/etc/kubernetes-pki-cluster/ca.pem \
  --service-account-private-key-file=/etc/kubernetes-pki-cluster/ca-key.pem \
  --cluster-signing-cert-file=/etc/kubernetes-pki-cluster/ca.pem \
  --cluster-signing-key-file=/etc/kubernetes-pki-cluster/ca-key.pem \
  # 集群运行模式，启用自动选举功能；被选为 leader 的节点负责处理工作
  --leader-elect=true \
  # 开启 kublet server 证书的自动更新特性
  --feature-gates=RotateKubeletServerCertificate=true \
  # 启用的控制器列表，tokencleaner 用于自动清理过期的 Bootstrap token
  --controllers=*,bootstrapsigner,tokencleaner \
  --horizontal-pod-autoscaler-use-rest-clients=true \
  --horizontal-pod-autoscaler-sync-period=10s \
  # Controller-Manager相关证书地址
  --tls-cert-file=/etc/kubernetes-pki-cluster/controller-manager/controller-manager.pem \
  --tls-private-key-file=/etc/kubernetes-pki-cluster/controller-manager/controller-manager-key.pem \
  --use-service-account-credentials=true \
  --alsologtostderr=true \
  --logtostderr=false \
  # 日志地址（注意：这个好像不起作用）
  --log-dir=/var/log/kubernetes \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

#### 十八、启动和简单测试Controller-Manager节点（注意：集群每个主节点都要执行）
```bash
$ sudo systemctl daemon-reload && systemctl start kube-controller-manager   # 启动 Controller-Manager
$ sudo systemctl daemon-reload && systemctl restart kube-controller-manager # 重启 Controller-Manager
$ sudo systemctl stop kube-controller-manager                               # 停止 Controller-Manager
$ sudo systemctl enable kube-controller-manager                             # 开启开机启动（建议开启）
$ sudo systemctl disable kube-controller-manager                            # 禁止开机启动

$ sudo service kube-controller-manager status                               # 查看 Controller-Manager 服务状态
$ journalctl -f -u kube-controller-manager                                  # 查看 Controller-Manager 日志
$ netstat -ntlp                                                             # 查看端口绑定情况（注意：应该绑定了一个10252的端口，这个端口是我们在上面的配置文件里面配置的）

# 获取所有组件的健康状态（注意：scheduler因为还没有部署所以是不健康的）
$ /opt/kubernetes-apiserver/server/bin/kubectl get componentstatuses 
NAME                 STATUS      MESSAGE                        ERROR
scheduler            Unhealthy   Get http://127.0.0.1:10251/healthz: dial tcp 127.0.0.1:10251: connect: connection refused   
controller-manager   Healthy     ok                                                     
etcd-0               Healthy     {"health":"true"}                                                                           
etcd-1               Healthy     {"health":"true"}                                                                           
etcd-2               Healthy     {"health":"true"}

# 查看 Leader信息
$ /opt/kubernetes-apiserver/server/bin/kubectl get endpoints kube-controller-manager --namespace=kube-system -o yaml
apiVersion: v1
kind: Endpoints
metadata:
  annotations:
    control-plane.alpha.kubernetes.io/leader: '{"holderIdentity":"server006_450d1f67-cad6-4328-88ef-3a1e24d67ae8","leaseDurationSeconds":15,"acquireTime":"2019-08-28T03:40:21Z","renewTime":"2019-08-28T03:58:19Z","leaderTransitions":0}'
  creationTimestamp: "2019-08-28T03:40:21Z"
  name: kube-controller-manager
  namespace: kube-system
  resourceVersion: "3322"
  selfLink: /api/v1/namespaces/kube-system/endpoints/kube-controller-manager
  uid: 585a4d8e-c4c7-4139-87d6-23c51010fe85
```

#### 十九、为每个Api Server节点（Master节点）的Scheduler创建配置文件（注意：修改成当前节点的IP或主机名，还有每个Api Server节点（Master节点）都要执行）
 - Scheduler启动后将通过竞争选举机制产生一个 Leader 节点，其它节点为阻塞状态。当 Leader 节点不可用后，剩余节点将再次进行选举产生新的 leader 节点，从而保证服务的可用性
 - 说明：这个和 HDFS 集群的 NameNode 高可用相似
```bash
# 创建并进入配置文件目录
$ mkdir -p /opt/kubernetes-apiserver/config && cd /opt/kubernetes-apiserver/config

# 创建配置文件（注意：修改成当前节点的地址）
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes-pki-cluster/ca.pem                 \
  --embed-certs=true                                                         \
  --server=https://server006:6443                                            \
  --kubeconfig=kube-scheduler.kubeconfig
 
# 设置证书相关配置
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-credentials system:kube-scheduler \
  --client-certificate=/etc/kubernetes-pki-cluster/scheduler/kube-scheduler.pem             \
  --client-key=/etc/kubernetes-pki-cluster/scheduler/kube-scheduler-key.pem                 \
  --embed-certs=true                                                                        \
  --kubeconfig=kube-scheduler.kubeconfig
  
# 设置上下文配置
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-context system:kube-scheduler     \
  --cluster=kubernetes                                                                      \
  --user=system:kube-scheduler                                                              \
  --kubeconfig=kube-scheduler.kubeconfig
 
# 设置默认上下文配置
$ /opt/kubernetes-apiserver/server/bin/kubectl config use-context system:kube-scheduler     \
  --kubeconfig=kube-scheduler.kubeconfig
```

#### 二十、[vi /etc/systemd/system/kube-scheduler.service] 为每个Api Server节点（Master节点）的Scheduler创建系统Service启动文件（注意：创建时要删除注释，否则会报错。还有每个Api Server节点（Master节点）都要创建），[kube-scheduler命令官方使用说明](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/)
```bash
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/opt/kubernetes-apiserver/server/bin/kube-scheduler \
  --address=127.0.0.1 \
  # Scheduler配置文件地址
  --kubeconfig=/opt/kubernetes-apiserver/config/kube-scheduler.kubeconfig \
  --leader-elect=true \
  --alsologtostderr=true \
  --logtostderr=false \
  # 日志地址（注意：这个好像不起作用）
  --log-dir=/var/log/kubernetes \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

#### 二一、启动和简单测试Scheduler节点（注意：集群每个主节点都要执行）
```bash
$ sudo systemctl daemon-reload && systemctl start kube-scheduler   # 启动 Kube-Scheduler
$ sudo systemctl daemon-reload && systemctl restart kube-scheduler # 重启 Kube-Scheduler
$ sudo systemctl stop kube-scheduler                               # 停止 Kube-Scheduler
$ sudo systemctl enable kube-scheduler                             # 开启开机启动（建议开启）
$ sudo systemctl disable kube-scheduler                            # 禁止开机启动

$ sudo service kube-scheduler status                               # 查看 Kube-Scheduler 服务状态
$ journalctl -f -u kube-scheduler                                  # 查看 Kube-Scheduler 日志
$ netstat -ntlp

# 获取所有组件的健康状态（注意：到这里了所有的组件都应该是健康的）
$ /opt/kubernetes-apiserver/server/bin/kubectl get componentstatuses 
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
scheduler            Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
etcd-1               Healthy   {"health":"true"}   
etcd-2               Healthy   {"health":"true"}

# 查看 Leader信息
$ /opt/kubernetes-apiserver/server/bin/kubectl get endpoints kube-scheduler --namespace=kube-system -o yaml
apiVersion: v1
kind: Endpoints
metadata:
  annotations:
    control-plane.alpha.kubernetes.io/leader: '{"holderIdentity":"server006_1f78e56d-9a10-464b-99d0-bd04295eb54f","leaseDurationSeconds":15,"acquireTime":"2019-08-29T02:09:30Z","renewTime":"2019-08-29T02:11:23Z","leaderTransitions":0}'
  creationTimestamp: "2019-08-29T02:09:30Z"
  name: kube-scheduler
  namespace: kube-system
  resourceVersion: "4238"
  selfLink: /api/v1/namespaces/kube-system/endpoints/kube-scheduler
  uid: 45d660c3-242d-4f6b-bf62-8694a4bae57d
```

#### 二二、下载和分发Work节点的Kubelet（因要翻墙下载，所以百度云有备份），[官方详细下载地址](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.15.md)，（注意：在任意一台主节点上创建部署文件，再将部署文件分发到所有的Work（从）节点）
```bash
# 下载Work（从）节点安装包
$ wget -P /home/tools/kubernetes/work https://dl.k8s.io/v1.15.3/kubernetes-node-linux-amd64.tar.gz

# 定位到主节点安装包目录
$ cd /home/tools/kubernetes/work

# 解压work（从）节点安装包并将里面的内容复制到/opt/kubernetes-work目录
$ tar -vxf kubernetes-node-linux-amd64.tar.gz &&   \
  mkdir -p /opt/kubernetes-work/data/kube-proxy && \
  mkdir -p /opt/kubernetes-work/data/kubelet &&    \
  mkdir -p /opt/kubernetes-work/log/kube-proxy &&  \
  scp -r ./kubernetes/* /opt/kubernetes-work

# 创建并进入配置文件目录
$ mkdir -p /opt/kubernetes-work/config && cd /opt/kubernetes-work/config

# 生成Kubelet的配置文件
# 定义生成 token 的变量
$ export BOOTSTRAP_TOKEN=$(/opt/kubernetes-apiserver/server/bin/kubeadm token create \
  --description kubelet-bootstrap-token                                              \
  --groups system:bootstrappers:worker                                               \
  --kubeconfig ~/.kube/config)
  
# 创建Kubelet配置文件（注意：Api Server的地址，最好使用Keepalived做高可用，然后配个虚拟ip或主机名放到这里）
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes-pki-cluster/ca.pem                 \
  --embed-certs=true                                                         \
  --server=https://server006:6443                                            \
  --kubeconfig=kubelet-bootstrap.kubeconfig
  
# 设置Kubelet客户端认证配置
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN}                                                            \
  --kubeconfig=kubelet-bootstrap.kubeconfig
  
# 设置Kubelet上下文配置
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-context default \
  --cluster=kubernetes                                                    \
  --user=kubelet-bootstrap                                                \
  --kubeconfig=kubelet-bootstrap.kubeconfig
  
# 设置Kubelet默认上下文配置
$ /opt/kubernetes-apiserver/server/bin/kubectl config use-context default \
  --kubeconfig=kubelet-bootstrap.kubeconfig

  
# 生成Kube-Proxy的配置文件
# 创建kube-proxy.kubeconfig（注意：Api Server的地址，最好使用Keepalived做高可用，然后配个虚拟ip或主机名放到这里）
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes-pki-cluster/ca.pem                 \
  --embed-certs=true                                                         \
  --server=https://server006:6443                                            \
  --kubeconfig=kube-proxy.kubeconfig
  
# 设置Kube-Proxy证书相关配置  
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-credentials kube-proxy \
  --client-certificate=/etc/kubernetes-pki-cluster/kube-proxy/kube-proxy.pem     \
  --client-key=/etc/kubernetes-pki-cluster/kube-proxy/kube-proxy-key.pem         \
  --embed-certs=true                                                             \
  --kubeconfig=kube-proxy.kubeconfig

# 设置Kube-Proxy上下文配置   
$ /opt/kubernetes-apiserver/server/bin/kubectl config set-context default \
  --cluster=kubernetes                                                    \
  --user=kube-proxy                                                       \
  --kubeconfig=kube-proxy.kubeconfig 
  
# 设置Kube-Proxy默认上下文配置
$ /opt/kubernetes-apiserver/server/bin/kubectl config use-context default \
  --kubeconfig=kube-proxy.kubeconfig   
  
# 分发安装包到集群的各个work（从）节点（注意：是work（从）节点）
$ scp -r /opt/kubernetes-work root@server008:/opt  
```

#### 二三、在每个work（从）节点上创建[vi /opt/kubernetes-work/config/kubelet.config.json] Kubelet的配置文件，注意修改当前节点的IP（注意：创建时要删除注释，否则会报错。还有每个work（从）节点都要创建）
```bash
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "authentication": {
    "x509": {
      # 根证书的地址
      "clientCAFile": "/etc/kubernetes-pki-cluster/ca.pem"
    },
    "webhook": {
      "enabled": true,
      "cacheTTL": "2m0s"
    },
    "anonymous": {
      "enabled": false
    }
  },
  "authorization": {
    "mode": "Webhook",
    "webhook": {
      "cacheAuthorizedTTL": "5m0s",
      "cacheUnauthorizedTTL": "30s"
    }
  },
  # 当前节点IP（注意：修改成自己的IP，一定是IP，否则报错）
  "address": "192.168.83.145",
  "port": 10250,
  "readOnlyPort": 10255,
  "cgroupDriver": "cgroupfs",
  "hairpinMode": "promiscuous-bridge",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletClientCertificate": true,
    "RotateKubeletServerCertificate": true
  },
  "clusterDomain": "cluster.local.",
  # 集群DNS地址（注意：我们下面部署CoreDNS绑定的服务IP就是这个）
  "clusterDNS": ["10.254.0.2"]
}
```

#### 二四、在每个work（从）节点上创建[vi /etc/systemd/system/kubelet.service] Kubelet Service的启动文件（注意：创建时要删除注释，否则会报错。还有每个work（从）节点都要创建），[官方kubelet命令使用说明](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet)
```bash
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
# 节点数据目录
WorkingDirectory=/opt/kubernetes-work/data/kubelet
ExecStart=/opt/kubernetes-work/node/bin/kubelet \
  # Kubelet 启动引导配置文件
  --bootstrap-kubeconfig=/opt/kubernetes-work/config/kubelet-bootstrap.kubeconfig \
  # 根证书地址
  --cert-dir=/etc/kubernetes-pki-cluster \
  # kubectl配置文件地址（注意：实际没有这个配置文件，这项配置好像没什么用，可以删除）
  --kubeconfig=/opt/kubernetes-work/config/kubectl.config \
  # Kubelet 配置文件
  --config=/opt/kubernetes-work/config/kubelet.config.json \
  # cgroup驱动（注意：这个需和docker的一致，建议都使用cgroupfs）
  --cgroup-driver=cgroupfs \
  # 指定网络插件
  --network-plugin=cni \
  # 指定镜像下载地址
  --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1 \
  --alsologtostderr=true \
  --logtostderr=false \
  # 日志地址（注意：这个好像不起作用）
  --log-dir=/var/log/kubernetes \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

#### 二五、启动work（从）节点的Kubelet服务和简单测试（注意：每个work（从）节点都要启动）
 - kublet 启动时查找配置的 --kubeletconfig 文件是否存在，如果不存在则使用 --bootstrap-kubeconfig 向 kube-apiserver 发送证书签名请求 (CSR)。 kube-apiserver 收到 CSR 请求后，对其中的 Token 进行认证（事先使用 kubeadm 创建的 token），认证通过后将请求的 user 设置为 system:bootstrap:，group 设置为 system:bootstrappers，这就是Bootstrap Token Auth
```bash
# 给Kubelet赋予访问Api Server的权限（注意：该命令在任意一台主节点上执行即可，注意是在主节点上执行）
$ /opt/kubernetes-apiserver/server/bin/kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper                                                   \
  --group=system:bootstrappers
  

$ systemctl daemon-reload && systemctl start kubelet    # 启动 Kubelet 服务
$ systemctl daemon-reload && systemctl restart kubelet  # 重启 Kubelet 服务
$ systemctl stop kubelet                                # 停止 Kubelet 服务
$ systemctl enable kubelet                              # 开启开机启动 Kubelet 服务（建议开启）
$ systemctl disable kubelet                             # 禁用开机启动 Kubelet 服务

$ service kubelet status                                # 查看 Kubelet 服务运行状态

# 查看 Kubelet 服务日志（注意：可能会报cni网络插件没有的错误，这个是因为cni网络插件Calico还没有部署，可以先忽略，等下面部署好了再看）
$ journalctl -f -u kubelet                             

# 在 Master（主）节点上 Approve（允许） bootstrap（从节点）加入集群的请求
# 获取从节点要加入集群的请求（注意：该命令在主节点上执行）
$ /opt/kubernetes-apiserver/server/bin/kubectl get csr  
# 通过从节点加集群的请求（注意：该命令在主节点上执行，<name>是请求的名称）
$ /opt/kubernetes-apiserver/server/bin/kubectl certificate approve <name>

# 在主节点上执行查看集群work（从）节点的信息（注意：STATUS是NotReady（不正常），可以先忽略，因为cni网络插件Calico还没有部署）
$ /opt/kubernetes-apiserver/server/bin/kubectl get nodes
NAME        STATUS   ROLES    AGE   VERSION
server008   NotReady    <none>   16h   v1.15.3
``` 

#### 二六、在每个work（从）节点上创建[vi /opt/kubernetes-work/config/kube-proxy.config.yaml] Kube-Proxy的配置文件（注意：修改成当前节点的IP，还有创建时要删除注释，否则会报错。还有每个work（从）节点都要创建）
```bash
apiVersion: kubeproxy.config.k8s.io/v1alpha1
# 服务绑定地址（注意：修改成当前节点的IP，注意一定是IP否则无法启动）
bindAddress: 192.168.83.145
clientConnection:
  # Kube-Proxy配置文件地址
  kubeconfig: /opt/kubernetes-work/config/kube-proxy.kubeconfig
# pod网段  
clusterCIDR: 172.22.0.0/16
# 绑定健康检查地址（注意：修改成当前节点的IP，注意一定是IP否则无法启动）
healthzBindAddress: 192.168.83.145:10256
kind: KubeProxyConfiguration
# 绑定监控检查地址（注意：修改成当前节点的IP，注意一定是IP否则无法启动）
metricsBindAddress: 192.168.83.145:10249
mode: "iptables"
```

#### 二七、在每个work（从）节点上创建[vi /etc/systemd/system/kube-proxy.service] Kube-Proxy Service的启动文件（注意：创建时要删除注释，否则会报错。还有每个work（从）节点都要创建），[kube-proxy命令官方使用说明](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/)
```bash
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
# Kube-Proxy数据存储目录
WorkingDirectory=/opt/kubernetes-work/data/kube-proxy
ExecStart=/opt/kubernetes-work/node/bin/kube-proxy \
  # Kube-Proxy配置文件目录
  --config=/opt/kubernetes-work/config/kube-proxy.config.yaml \
  --alsologtostderr=true \
  --logtostderr=false \
  # 日志存储目录
  --log-dir=/opt/kubernetes-work/log/kube-proxy \
  --v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

#### 二八、启动work（从）节点的Kube-Proxy服务和简单测试（注意：每个work（从）节点都要启动）
```bash
$ systemctl daemon-reload && systemctl start kube-proxy   # 启动 Kube-Proxy 服务
$ systemctl daemon-reload && systemctl restart kube-proxy # 重启 Kube-Proxy 服务
$ systemctl stop kube-proxy                               # 停止 Kube-Proxy 服务
$ systemctl enable kube-proxy                             # 开启开机启动 Kube-Proxy 服务（建议开启）
$ systemctl disbale kube-proxy                            # 禁用开机启动 Kube-Proxy 服务

$ service kube-proxy status                               # 查看 Kube-Proxy 服务运行状态
$ journalctl -f -u kube-proxy                             # 查看 Kube-Proxy 服务运行日志
```

#### 二九、部署CNI插件 - Calico，[官方安装文档](https://docs.projectcalico.org/v3.8/getting-started/kubernetes/installation/calico#installing-with-the-kubernetes-api-datastoremore-than-50-nodes)，（注意：以下命令在任意一台主节点上执行即可，从节点会自动部署）
```bash
# 创建并定位到存放部署Calico配置文件目录
$ mkdir -p /opt/kubernetes-apiserver/addons && cd /opt/kubernetes-apiserver/addons

# 从官方下载Calico安装的配置文件
$ curl https://docs.projectcalico.org/v3.8/manifests/calico-typha.yaml -O

# 修改pod网段，我们上面的配置文件里面使用的是：172.22.0.0/16，所以要修改成它
$ POD_CIDR="172.22.0.0/16" && sed -i -e "s?192.168.0.0/16?$POD_CIDR?g" calico-typha.yaml

# 部署Calico（注意：可以修改calico-typha.yaml文件里面的replicas属性来指定Calico的部署副本数（默认是1，就是同时部署2个Calico），-f是指定配置文件）
$ /opt/kubernetes-apiserver/server/bin/kubectl apply -f calico-typha.yaml

# 查看Calico部署状态
$ /opt/kubernetes-apiserver/server/bin/kubectl get pods -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-65b8787765-hmh8m   1/1     Running   0          2m17s
calico-node-2zl8m                          1/1     Running   0          2m17s
calico-typha-5d845864c4-h5wch              1/1     Running   0          2m17s

# 查看集群所有work（从）节点的状态（注意：STATUS应该都是Ready（正常）状态，因为Calico部署成功了）
$ /opt/kubernetes-apiserver/server/bin/kubectl get nodes
NAME        STATUS   ROLES    AGE   VERSION
server008   Ready    <none>   16h   v1.15.3

# 到work（从）节点上执行看看Kubelet的日志是否正常（不应该再报cni网络插件没有的错误，因为我们已经部署好了cni网络插件Calico）
$ journalctl -f -u kubelet
```

#### 三十、部署DNS服务 - CoreDNS（注意：以下命令在任意一台主节点上执行即可）
```bash
# 创建并定位到存放部署CoreDNS配置文件目录
$ mkdir -p /opt/kubernetes-apiserver/addons && cd /opt/kubernetes-apiserver/addons

# 创建部署CoreDNS配置文件
$ cat > /opt/kubernetes-apiserver/addons/coredns.yaml <<EOF
# __MACHINE_GENERATED_WARNING__

apiVersion: v1
kind: ServiceAccount
metadata:
  name: coredns
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: Reconcile
  name: system:coredns
rules:
- apiGroups:
  - ""
  resources:
  - endpoints
  - services
  - pods
  - namespaces
  verbs:
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: EnsureExists
  name: system:coredns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:coredns
subjects:
- kind: ServiceAccount
  name: coredns
  namespace: kube-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local. in-addr.arpa ip6.arpa {
            pods insecure
            upstream
            fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . /etc/resolv.conf
        cache 30
        reload
    }
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "CoreDNS"
spec:
  # 默认部署副本数是1
  # replicas: not specified here:
  # 1. In order to make Addon Manager do not reconcile this replicas parameter.
  # 2. Default is 1.
  # 3. Will be tuned in real time if DNS horizontal auto-scaling is turned on.
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
      annotations:
        seccomp.security.alpha.kubernetes.io/pod: 'docker/default'
    spec:
      serviceAccountName: coredns
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      containers:
      - name: coredns
        # 镜像
        image: coredns/coredns:1.4.0
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
      dnsPolicy: Default
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  annotations:
    prometheus.io/port: "9153"
    prometheus.io/scrape: "true"
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "CoreDNS"
spec:
  selector:
    k8s-app: kube-dns
  # 绑定集群DNS服务地址  
  clusterIP: 10.254.0.2
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
EOF    

# 部署 CoreDNS
$ /opt/kubernetes-apiserver/server/bin/kubectl apply -f coredns.yaml

# 查看所有pod的部署状态
$ /opt/kubernetes-apiserver/server/bin/kubectl get pods -n kube-system
```