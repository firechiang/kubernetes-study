#### 一、Taint（污点）简单使用（注意：污点的目的是要让Pod不能自动部署在该Node（节点）上，除非Pod在部署是指定容忍该污点，才可部署在该Node（节点）上）
```bash
# 获取集群所有的节点
$ kubectl get nodes

# 给Node（节点）打上污点：gpu=true:NoSchedule （NoSchedule是指不能调度，除非容忍污点）
# 注意：NoSchedule 不是随便起的，是Kubernetes污点自带的规则，它有3个，其它2个可自行百度
$ kubectl taint nodes [节点的名称（可使用上面的命令查看）] gpu=true:NoSchedule

# 删除Node（节点）的污点（其实和打污点的命令一致，只是在最后加了一个减号）
$ kubectl taint nodes [节点的名称（可使用上面的命令查看）] gpu=true:NoSchedule-

# 查看Node（节点）是否打上污点（注意查看有没有：Taints: gpu=true:NoSchedule）
$ kubectl describe node [节点的名称（可使用上面的命令查看）]
```
#### 二、Pod容忍污点配置示例（就是这个Pod要部署在有污点的机器上）
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springboot-demo-taint
  namespace: dev
spec:
  selector:
    matchLabels:
      app: springboot-demo-taint
  replicas: 1
  template:
    metadata:
      labels:
        app: springboot-demo-taint
    spec:
      containers:
      - name: springboot-demo-taint
        image: chiangfire/springboot-demo:20191122051537
        ports:
        - containerPort: 2019
      # 容忍污点配置 
      tolerations:
      # 要匹配的key
      - key: "gpu"
        # 匹配模式 
        operator: "Equal"
        # 要匹配的值
        value: "true"
        # 污点效果（注意：这个效果要和我们打污点时所使用的一致）
        effect: "NoSchedule"
```