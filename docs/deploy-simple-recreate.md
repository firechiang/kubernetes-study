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
    # 先将原有的服务杀掉重新部署
    type: Recreate
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
        # 健康检查的配置（pod存活的探针配置）
        livenessProbe:
          tcpSocket:
            port: 2019
          initialDelaySeconds: 20
          periodSeconds: 10
          failureThreshold: 2
          successThreshold: 1
          timeoutSeconds: 5
        # 以下检查通过以后才会把服务挂载到负载均衡器（pod是否启动好的探针配置） 
        readinessProbe:
          httpGet:
            path: /host
            port: 2019
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 5
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

#### 二、创建部署服务（先将原有的服务杀掉重新部署）
```bash
# 部署服务
$ kubectl apply -f deploy-simple-recreate.yaml

# 查看所有的Pod信息
$ kubectl get pods -n dev

# 查看所有的部署信息
$ kubectl get deploy -n dev
NAME              READY   UP-TO-DATE   AVAILABLE（有几个已经对外提供服务了）   AGE
springboot-demo   2/2     2            2                                   102s
```