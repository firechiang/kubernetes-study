#### 一、部署配置示例
```bash
#deploy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springboot-demo
  # Deployment指定部署在dev的Namespace下
  namespace: dev
spec:
  # 部署策略
  strategy:
    # 滚动部署 
    rollingUpdate:
      # 最大可超出服务实列数的百分比 （比如最大4个实列，那么在部署时最大可启动6个实列）
      # 注意：把百分号去掉指的时数量
      maxSurge: 50%
      # 最大不可用的服务实列数的百分比 （比如最大4个实列，那么最多只能有一个2实列不可用）
      # 注意：把百分号去掉指的时数量
      maxUnavailable: 50%
    type: RollingUpdate
  selector:
    # 匹配标签（就是这个Deployment只管理带有app=springboot-demo标签的Pod）
    matchLabels:
      app: springboot-demo
  # 部署实列数 
  replicas: 2
  # 创建Pod的配置
  template:
    metadata:
      # 为Pod打上app=springboot-demo标签（如果没有这个Deployment将无法部署）
      labels:
        app: springboot-demo
    spec:
      containers:
      - name: springboot-demo
        image: chiangfire/springboot-demo:20191122051537
        ports:
        # 注意：这个端口要和服务本身启动起来的端口相同
        - containerPort: 2019
        # 资源限制
        resources:
          requests:
            memory: 1024Mi
            cpu: 500m
          limits:
            memory: 2048Mi
            cpu: 2000m
        # 健康检查的配置（pod存活的探针配置）   
        livenessProbe:
          tcpSocket:
            port: 2019
          initialDelaySeconds: 20
          periodSeconds: 10
          failureThreshold: 3
          successThreshold: 1
          timeoutSeconds: 5
        # 以下检查通过以后才会把服务挂载到负载均衡器（pod是否启动好的探针配置） 
        readinessProbe:
          httpGet:
            path: /host
            port: 2019
            scheme: HTTP
          initialDelaySeconds: 20
          periodSeconds: 10
          failureThreshold: 1
          successThreshold: 1
          timeoutSeconds: 5
---
#service
apiVersion: v1
kind: Service
metadata:
  name: springboot-demo
  namespace: dev
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 2019
  selector:
    app: springboot-demo
  type: ClusterIP

---
#ingress
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: springboot-demo
  namespace: dev
spec:
  rules:
  # 访问这个域名即可访问到服务
  - host: springboot-demo.mooc.com
    http:
      paths:
      - path: /
        backend:
          serviceName: springboot-demo
          servicePort: 80
```

#### 二、创建部署服务（先启动新服务再停止旧服务）
```bash
# 部署服务
$ kubectl apply -f deploy-simple-rollingupdate.yaml

# 启动一个新服务以后执行该命令，可暂停部署，然后看看新服务是否有什么问题，如果没有问题可执行其它命令继续部署
#$ kubectl rollout pause deploy springboot-demo -n dev    # 暂停 
#$ kubectl rollout resume deploy springboot-demo -n dev   # 继续

# 回滚部署（如果发现升级有问题，执行该命令，可快速回滚到上一个版本）
#$ kubectl rollout undo deploy springboot-demo -n dev

# 查看所有的Pod信息
$ kubectl get pods -n dev

# 查看所有的部署信息
$ kubectl get deploy -n dev
NAME              READY   UP-TO-DATE   AVAILABLE（有几个已经对外提供服务了）   AGE
springboot-demo   2/2     2            2                                   102s

# 查看部署的详细配置
$ kubectl get deploy springboot-demo -o yaml -n dev
```