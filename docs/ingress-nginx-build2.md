#### 一、[Ingress代理转发服务官方说明](https://kubernetes.io/zh/docs/concepts/services-networking/ingress/)
#### 二、[Ingress类型和控制器官方说明](https://kubernetes.io/zh/docs/concepts/services-networking/ingress-controllers/)
#### 三、[Ingress-Nginx项目（GitHub）](https://github.com/kubernetes/ingress-nginx)
#### 四、[Ingress-Nginx官方使用文档](https://kubernetes.github.io/ingress-nginx/)
#### 五、编辑Ingress-Nginx[mkdir -p /home/kubernetes-deployment/ingress-nginx && vi /home/kubernetes-deployment/ingress-nginx/ingress-nginx-deployment.yaml]部署文件，[官方Ingress-Nginx部署文件](https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml)
```bash
apiVersion: v1
# 命名空间
kind: Namespace
metadata:
  name: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
# 用于存储Nginx配置的ConfigMap
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
# 用于存储4层代理TCP相关配置（比如端口映射等等）的ConfigMap
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
# 权限相关配置
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: nginx-ingress-clusterrole
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    # 需要获取的资源 
    resources:
      - configmaps
      - endpoints
      - nodes
      - pods
      - secrets
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses/status
    verbs:
      - update

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: nginx-ingress-role
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - pods
      - secrets
      - namespaces
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - configmaps
    resourceNames:
      # Defaults to "<election-id>-<ingress-class>"
      # Here: "<ingress-controller-leader>-<nginx>"
      # This has to be adapted if you change either parameter
      # when launching the nginx-ingress-controller.
      - "ingress-controller-leader-nginx"
    # 配置有获取和修改资源  configmaps 的权限
    verbs:
      - get
      - update
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - create
  - apiGroups:
      - ""
    resources:
      - endpoints
    verbs:
      - get

---
apiVersion: rbac.authorization.k8s.io/v1beta1
# 角色绑定
kind: RoleBinding
metadata:
  name: nginx-ingress-role-nisa-binding
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-ingress-role
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
# 集群角色绑定
kind: ClusterRoleBinding
metadata:
  name: nginx-ingress-clusterrole-nisa-binding
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-ingress-clusterrole
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---
# 这个service的配置新加的，因为如果没有这个service会一直打印一个警告说找不到ingress-nginx service
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  externalTrafficPolicy: Local
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
  ports:
    - name: http
      port: 80
      targetPort: http
    - name: https
      port: 443
      targetPort: https
      
---
apiVersion: apps/v1
# 部署相关信息（DaemonSet=Node的守护进程）
kind: DaemonSet
metadata:
  name: nginx-ingress-controller
  # 指定命名空间
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  # 节点选择（匹配标签）
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/part-of: ingress-nginx
  # 更新策略（重新部署模式，比如：滚动部署、蓝绿部署、金丝雀部署等等）
  updateStrategy:
    rollingUpdate:
      # 停掉1个更新1个
      maxUnavailable: 1
    # 滚动更新  
    type: RollingUpdate    
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      # wait up to five minutes for the drain of connections
      terminationGracePeriodSeconds: 300
      serviceAccountName: nginx-ingress-serviceaccount
      # host网络模式运行（注意：这个配置是新加的，目的是提高网络效率（没有转发）和绑定宿主机端口，以对外提供服务）
      hostNetwork: true
      # 节点选择器
      nodeSelector:
        #kubernetes.io/os: linux
        # Ingress-Nginx会部署在具有app=ingress-nginx标签的节点上（注意：这个配置是新加的，目的是让ingress-nginx部署在指定节点上）
        app: ingress-nginx
      containers:
        - name: nginx-ingress-controller
          # 指定阿里云的镜像
          #image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.26.1
          image: registry.cn-hangzhou.aliyuncs.com/google_containers/nginx-ingress-controller:0.26.1
          # 配置容器运行参数
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
            - --annotations-prefix=nginx.ingress.kubernetes.io
          securityContext:
            allowPrivilegeEscalation: true
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
            # www-data -> 33
            runAsUser: 33
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: http
              containerPort: 80
            - name: https
              containerPort: 443
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          lifecycle:
            preStop:
              exec:
                command:
                  - /wait-shutdown

---
```
#### 六、部署Ingress-Nginx
```bash
# 获取集群所有的节点信息
$ kubectl get nodes

# 给某个节点打个标签，让Ingress-Nginx部署在该节点上（注意：可以在多个节点上打上标签，都运行Ingress-Nginx）
# 注意：上面部署文件里面配置了节点选择器，会部署在具有app=ingress-nginx标签的节点上
# （可使用kubectl get nodes命令查看）
#                     node名称       标签
#                        |            |
$ kubectl label node server002 app=ingress-nginx

# 修改标签（注意：这个命令不需要执行）
# kubectl label node server002 app=ingress-nginx1 --overwrite

# 删除标签，只需在命令行最后指定Label的key名并与一个减号相连即可（注意：这个命令不需要执行）
# kubectl label node server002 app-

# 查看所有节点以及节点的Label，看看上面添加的Label是否有了
$ kubectl get node --show-labels

# apply表示修改或创建部署（也可以使用create代替），-f 表示指定部署配置文件
$ kubectl apply -f /home/kubernetes-deployment/ingress-nginx/ingress-nginx-deployment.yaml

# 查看ingress-nginx部署信息（注意查看是不是部署在具有app=ingress-nginx标签的节点上）
$ kubectl get all -n ingress-nginx

# 查看ingress-nginx命名空间下所有的部署
$ kubectl get DaemonSet -n ingress-nginx
# 查看ingress-nginx命名空间下nginx-ingress-controller部署的详细配置
$ kubectl get DaemonSet -n ingress-nginx nginx-ingress-controller -o yaml
```

#### 七、测试 Ingress-Nginx（说明：其实就我们部署一个服务看看Ingress-Nginx能不能转发）
##### 7.1、创建测试部署文件[vi /home/kubernetes-deployment/ingress-nginx/ingress-demo.yaml]注意：如果文件内容没有格式化，可以在编辑状态下使用：:set paste 命令格式化
```bash
#deploy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat-demo
spec:
  selector:
    matchLabels:
      app: tomcat-demo
  replicas: 1
  template:
    metadata:
      labels:
        app: tomcat-demo
    spec:
      containers:
      - name: tomcat-demo
        image: registry.cn-hangzhou.aliyuncs.com/liuyi01/tomcat:8.0.51-alpine
        ports:
        - containerPort: 8080
---
#service
apiVersion: v1
kind: Service
metadata:
  name: tomcat-demo
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: tomcat-demo

---
#ingress
apiVersion: extensions/v1beta1
# Ingress 相关配置
kind: Ingress
metadata:
  name: tomcat-demo
spec:
  rules:
  # 配置转发域名，注意修改（当访问这个域名的时候，会自动转发到当前这个服务）
  # 注意：这个域名绑定的IP需是装有ingress-nginx的节点，如果没有公网域名，可配置主机host域名测试
  - host: tomcat.mooc.com
    http:
      paths:
      - path: /
        backend:
          serviceName: tomcat-demo
          servicePort: 80
```
##### 7.2、部署测试服务，测试ingress-nginx是否可用（说明：使用部署测试服务，配置文件里面配置的ingress域名访问，看看会不会转发到当前服务上来）
```bash
$ cd /home/kubernetes-deployment/ingress-nginx

# 部署测试服务（apply表示修改或创建部署（也可以使用create代替），-f 表示指定部署配置文件）
$ kubectl apply -f ingress-demo.yaml

# 查看测试服务是否部署起来
$ kubectl get pod -o wide
```

