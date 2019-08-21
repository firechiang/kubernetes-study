### 简单测试集群的可用性（注意：以下命令须在主节点上执行）
#### 一、测试创建部署 Nginx ds
```bash
# 创建一个保存测试文件的目录，并进去
$ mkdir -p /home/kubernetes/test && cd /home/kubernetes/test

# 创建配置
$ cat > nginx-ds.yml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-ds
  labels:
    app: nginx-ds
spec:
  type: NodePort
  selector:
    app: nginx-ds
  ports:
  - name: http
    port: 80
    targetPort: 80
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: nginx-ds
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  template:
    metadata:
      labels:
        app: nginx-ds
    spec:
      containers:
      - name: my-nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
EOF

# 创建部署 Nginx-ds
$ kubectl create -f nginx-ds.yml

# 获取所有非系统pod，看看Nginx ds是否部署了
$ kubectl get pods

# 获取所有非系统pod(-o wide参数是指显示详细信息，比如该应用部署在那个节点上，内部IP是多少)
$ kubectl get pods -o wide
NAME             READY   STATUS    RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
nginx-ds-jn62b   1/1     Running   0          23m   172.22.150.193   server008   <none>           <none>

# 查看所有service的信息，看看是否有Nginx-ds
$ kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        55m
nginx-ds     NodePort    10.102.140.207   <none>        80:30213/TCP   12m

# 在每个节点上ping pod ip（正常应该都是可以ping通的）
$ ping <pod-ip>

# 在每个节点上访问服务（注意：service-ip就是service信息的CLUSTER-IP，正常的话应该是每个节点都可以访问）
# 示例：curl 10.102.140.207:80
$ curl <service-ip>:<port>

# 在每个节点检查node-port可用性（注意：node-port（服务绑定在节点的端口），是service信息里面PORT(S)项里面后面的那一个端口。正常的话应该是每个节点都可以访问）
# 示例：curl server008:30213
$ curl <node-ip>:<port>
```

#### 二、测试检查DNS的可用性
```bash
# 创建一个保存测试文件的目录，并进去
$ mkdir -p /home/kubernetes/test && cd /home/kubernetes/test

# 创建一个nginx pod
$ cat > pod-nginx.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.7.9
    ports:
    - containerPort: 80
EOF

# 创建Nginx的pod
$ kubectl create -f pod-nginx.yaml

# 查看所有pod的详细信息，看看有没有Nginx的pod
$ kubectl get pods -o wide
NAME             READY   STATUS    RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
nginx            1/1     Running   0          30s   172.22.150.194   server008   <none>           <none>
nginx-ds-jn62b   1/1     Running   0          31m   172.22.150.193   server008   <none>           <none>

# 进入Nginx的pod（就是进入容器），查看dns
$ kubectl exec  nginx -i -t -- /bin/bash

# 查看DNS配置信息
$ cat /etc/resolv.conf
----------信息打印start-------------
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local localdomain
options ndots:5
----------信息打印end-------------

# 注意：这个ping不会一直打印返回数据，只会解析IP和打印一次
# 查看名字是否可以正确解析（注意：nginx-ds是我们测试创建部署 Nginx ds所创建的）
# 正常的话，解析出来的IP和我们使用kubectl get svc命令获取所有service信息时，所看到的nginx-ds的IP一致
$ ping nginx-ds

# 退出Nginx的pod（就是退出容器）
$ exit
```