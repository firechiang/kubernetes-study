#### 一、Namespace主要用于隔离（Kubernetes集群搭建好以后，会有一个默认的命名空间default）
 - 资源对象的隔离，比如：Service，Deployment， Pod
 - 资源配额的隔离，比如：CPU，Memory
```bash
$ kubectl get namespaces                # 获取所有的命名空间
$ kubectl get pods -n default           # 获取default命名空间下所有的pod（-n就是指定命名空间）
```

#### 二、创建 [vi namespace-dev.yaml] Namespace命名空间
```bash
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  
$ kubectl create -f namespace-dev.yaml  # 创建Namespace
$ kubectl get namespaces                # 获取所有的命名空间（看看有没有我们刚刚创建的dev）
```

#### 三、部署服务到某个命名空间下
```bash

```

