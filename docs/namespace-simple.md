#### 一、Namespace主要用于隔离，也就是名字的隔离（不隔离IP），（Kubernetes集群搭建好以后，会有一个默认的命名空间default）
 - 资源对象的隔离，比如：Service，Deployment， Pod
 - 资源配额的隔离，比如：CPU，Memory
```bash
$ kubectl get namespaces                # 获取所有的命名空间
$ kubectl get pods -n default           # 获取default命名空间下所有的pod（-n就是指定命名空间）
$ kubectl get all -n default            # 获取default命名空间下的所有东西
```
#### 二、Namespace的使用方式
 - 按环境 dev，test划分
 - 按团队划分

#### 三、创建 [vi namespace-dev.yaml] Namespace命名空间
```bash
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  
$ kubectl create -f namespace-dev.yaml  # 创建Namespace
$ kubectl get namespaces                # 获取所有的命名空间（看看有没有我们刚刚创建的dev）
```

#### 四、部署服务到某个命名空间下
```bash
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/namespace/springboot-demo-dev.yaml
$ kubectl get pods -n dev -o wide       # 查看dev Namespace下所有的pod（-n就是指定命名空间）
$ kubectl get all -n dev                # 查看dev Namespace下所有东西
```

#### 五、测试不同命名空间下的服务是否可以使用名字相互访问（答案是：不行的，不同命名空间下的服务用名字不能相互访问，用IP可以）
```bash
# 进入某个pod的内部（springboot-demo-f8b845dfc-kkl6v是pod的名称）
$ kubectl exec -it springboot-demo-f8b845dfc-kkl6v /bin/sh -n dev

# 查看该容器的DNS设置（我们可以看到它的搜索范围是从dev.svc.cluster.local开始的）
# 如果是default命名空间，就应该是default.svc.cluster.local
$ cat /etc/resolv.conf 
nameserver 10.254.0.2
search dev.svc.cluster.local. svc.cluster.local. cluster.local. localdomain
options ndots:5
```

#### 六、修改kubectl命令，每次执行自动指定Namespace（注意：不建议修改）
```bash
# 设置新的上下文它的名字是：context-default（注意：这个命令就是修改/root/.kube/config配置文件的信息）
$ kubectl config set-context context-default --namespace=default --cluster=kubernetes --user=admin --kubeconfig=/root/.kube/config
# 设置所使用的上下文
$ kubectl config use-context context-default --kubeconfig=/root/.kube/config
```
