#### 一、集群集群节点说明（注意：ETCD和ZK的算法相同，建议ETCD集群的节点数是大于等3的基数个）
```bash
-----------|------------|
           |    ETCD    | 
-----------|------------|
server006  |     Y      |
-----------|------------|
server007  |     Y      |           
-----------|------------|
server008  |     Y      |
-----------|------------|
```

#### 二、安装CA证书工具cfssl（注意：随便找一台机器安装并生成CA证书，最后将证书拷贝到其它节点即可）
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

#### 三、生成CA根证书（注意：在装有cfssl工具的节点上执行生成CA根证书，其它节点要生成证书在该节点生成即可，然后再拷贝到集群的各个节点即可）
```bash
# 创建存放根证书目录
$ mkdir -p /home/cfssl/pki/etcd

# 创建config配置文件（注意：证书的过期时间是87600小时）
$ cat > /home/cfssl/pki/etcd/ca-config.json <<EOF
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
$ cat > /home/cfssl/pki/etcd/ca-csr.json <<EOF
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
$ cd /home/cfssl/pki/etcd/

# 生成证书和私钥
$ /home/cfssl/bin/cfssl gencert -initca ca-csr.json | /home/cfssl/bin/cfssljson -bare ca

# 生成完成后会有以下文件（我们最终想要的就是ca-key.pem和ca.pem，一个秘钥，一个证书）
$ ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem
```

#### 四、生成ETCD的证书（注意：在装有cfssl工具的节点上执行生成证书，最后将证书拷贝到其它节点即可）
```bash
# 创建并定位到存放ETCD的证书目录
$ cd /home/cfssl/pki/etcd

# 创建ETCD的csr配置文件（注意：要修改ETCD节点的主机名）
$ cat > /home/cfssl/pki/etcd/etcd-csr.json <<EOF
{
  "CN": "etcd",
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
      "O": "k8s",
      "OU": "seven"
    }
  ]
}
EOF

# 生成证书、私钥（注意：\代表命令换行的意思）
$ /home/cfssl/bin/cfssl gencert               \
  -ca=/home/cfssl/pki/etcd/ca.pem             \
  -ca-key=/home/cfssl/pki/etcd/ca-key.pem     \
  -config=/home/cfssl/pki/etcd/ca-config.json \
  -profile=kubernetes /home/cfssl/pki/etcd/etcd-csr.json | /home/cfssl/bin/cfssljson -bare etcd
  
# 生成完成后会有以下文件（我们最终想要的就是etcd-key.pem和etcd.pem，一个秘钥，一个证书）
$ ls
etcd.csr  etcd-csr.json  etcd-key.pem  etcd.pem  

# 创建证书存放目录并将证书复制到该目录
$ mkdir -p /etc/kubernetes/pki/etcd && scp /home/cfssl/pki/etcd/*.pem /etc/kubernetes/pki/etcd/

# 分发CA根证书和ETCD证书到集群的各个节点
$ scp -r /etc/kubernetes root@server007:/etc
$ scp -r /etc/kubernetes root@server008:/etc
```

#### 五、下载和分发ETCD安装包（注意：以下操作在集群当中，随便找一个节点操作即可）
```bash
# 创建ETCD的安装目录和数据存储目录（注意：集群所有的节点都要执行）
$ mkdir -p /opt/kubernetes/bin/etcd && mkdir -p /var/lib/etcd

# 下载安装包
$ wget -P /home/tools/kubernetes https://github.com/etcd-io/etcd/releases/download/v3.3.15/etcd-v3.3.15-linux-amd64.tar.gz

# 定位到下载目录
$ cd /home/tools/kubernetes

# 解压安装包并将里面的内容复制到/opt/kubernetes/bin/etcd目录
$ tar -zxvf etcd-v3.3.15-linux-amd64.tar.gz && scp -r ./etcd-v3.3.15-linux-amd64/* /opt/kubernetes/bin/etcd

# 分发ETCD安装包到集群的各个节点
$ scp -r /opt/kubernetes root@server007:/opt
$ scp -r /opt/kubernetes root@server008:/opt
```

#### 六、在集群的各个节点上创建 [vi /etc/systemd/system/etcd.service] ETCD Service系统启动文件（注意：IP和主机名要修改成各个节点自己的，而且创建文件时，要删除注释，否则会报错）
```bash
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
  # 当前节点的名称（注意：修改成自己的主机名）
  --name=server006 \
  --cert-file=/etc/kubernetes/pki/etcd/etcd.pem \
  --key-file=/etc/kubernetes/pki/etcd/etcd-key.pem \
  --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \
  --peer-cert-file=/etc/kubernetes/pki/etcd/etcd.pem \
  --peer-key-file=/etc/kubernetes/pki/etcd/etcd-key.pem \
  --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  # 监听集群内部通信地址（监听其他 Etcd 实例的地址）
  --listen-peer-urls=https://0.0.0.0:2380 \
  # 监听客户端通信地址（注意：因为老版本使用的是4001端口，所以这里配了两个地址）
  --listen-client-urls=https://0.0.0.0:2379,http://127.0.0.1:4001 \
  # 集群内部访问本节点的地址（注意：修改成自己的主机名或IP）
  --initial-advertise-peer-urls=https://server006:2380 \
  # 客户端访问本节点的地址（注意：修改成自己的主机名或IP）
  --advertise-client-urls=https://server006:2379 \
  # 集群ID（注意：每个节点配置需要一致）
  --initial-cluster-token=etcd-cluster-0 \
  # ETCD集群所有节点的信息（注意：server006是--name 指定的名字。后面的那个地址一定要在证书的host里面，否则集群内部无法连通）
  --initial-cluster=server006=https://server006:2380,server007=https://server007:2380,server008=https://server008:2380 \
  --initial-cluster-state=new
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

#### 七、启动ETCD的各个节点（注意：集群的各个节点都要执行）
```bash
$ sudo systemctl start etcd                  # 启动ETCD
$ sudo systemctl stop etcd                   # 停止ETCD
$ sudo systemctl restart etcd                # 重启ETCD
$ sudo systemctl enable etcd                 # 开启开机启动
$ sudo systemctl disable etcd                # 禁止开机启动
$ sudo systemctl daemon-reload               # 重启守护进程
```

#### 八、简单测试
```bash
# 查看ETCD服务日志
$ journalctl -f -u etcd.service

# 查看ETCD版本
$ /opt/kubernetes/bin/etcd/etcd --version    

# 查看ETCD控制命令使用帮助
$ /opt/kubernetes/bin/etcd/etcdctl -h      

# 查看集群节点信息（注意：因为我们添加了安全验证，所以必须携带证书访问，否则会报错）
$ /opt/kubernetes/bin/etcd/etcdctl            \
  --ca-file=/etc/kubernetes/pki/ca.pem        \
  --cert-file=/etc/kubernetes/pki/etcd.pem    \
  --key-file=/etc/kubernetes/pki/etcd-key.pem \
  member list

# 查看集群的健康状态（注意：因为我们添加了安全验证，所以必须携带证书访问，否则会报错）
$ /opt/kubernetes/bin/etcd/etcdctl            \
  --ca-file=/etc/kubernetes/pki/ca.pem        \
  --cert-file=/etc/kubernetes/pki/etcd.pem    \
  --key-file=/etc/kubernetes/pki/etcd-key.pem \
  cluster-health
```


