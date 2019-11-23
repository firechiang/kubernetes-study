#### 一、Label简单说明
 - Label就是key=value键值对
 - Label可以贴到Pod,Deployment,Service,Node等Kubernetes资源上
 - Label一旦被定义，不能直接修改，要先删除，再修改
```bash
# 给节点server002打上name=springboot-demo的标签（当然也可以为其它资源打上标签）
$ kubectl label node server002  name=springboot-demo 
# 查询带有标签name=springboot-demo的节点（当然也可以使用Label查询其它的资源）
$ kubectl get node -l name=springboot-demo  
# 查询带有标签app=dev或者app=test的Pod
$ kubectl get node -l 'app in (dev,test)'  
```
#### 二、Label使用配置示例
```bash
#deploy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springboot-demo
  # Deployment指定部署在dev的Namespace下
  namespace: dev
spec:
  selector:
    # 匹配标签（就是这个Deployment只管理带有app=springboot-demo标签的Pod）
    matchLabels:
      app: springboot-demo
    # 匹配标签key是group，value在dev和test当中即可 （注意：这个要和上面的如果同时存在就是并且的关系）
    matchExpressions:
      - {key: group,operator: In,values: [dev,test]}  
  replicas: 1
  # 创建Pod的配置
  template:
    metadata:
      labels:
        # 为Pod打上app=springboot-demo标签（如果没有这个Deployment将无法部署）
        app: springboot-demo
        group: dev
    spec:
      containers:
      - name: springboot-demo
        image: chiangfire/springboot-demo:20191122051537
        ports:
        # 注意：这个端口要和服务本身启动起来的端口相同
        - containerPort: 2019
    # 当前服务只部署在带有标签 name=springboot-demo的Node上
    nodeSelector:
      name: springboot-demo      
---
#service
apiVersion: v1
kind: Service
metadata:
  name: springboot-demo
  # Service指定部署在dev的Namespace下
  namespace: dev
spec:
  ports:
  - port: 80
    protocol: TCP
    # 注意：这个端口要和服务本身启动起来的端口相同
    targetPort: 2019
  selector:
    # 匹配标签（就是这个Service只管理带有app=springboot-demo标签的Pod）
    app: springboot-demo
  type: ClusterIP

---
#ingress
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: springboot-demo
  # Ingress指定部署在dev的Namespace下
  namespace: dev
spec:
  rules:
  # 访问这个域名 Ingress 会自动代理到当前服务（注意：Ingress要提前部署好）
  - host: web.springbootdemo.com
    http:
      paths:
      - path: /
        backend:
          serviceName: springboot-demo
          servicePort: 80
```