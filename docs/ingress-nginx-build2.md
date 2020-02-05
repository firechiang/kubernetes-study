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
          # ingress-nginx运行命令（--表示的是参数）
          # 更多运行参数，可等ingress-nginx跑起来之后进入其容器，执行命令：/nginx-ingress-controller --help 查看
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
            - --annotations-prefix=nginx.ingress.kubernetes.io
            # 指定https证书（注意：default表示Secret的命名空间，mooc-tls表示Secret证书的名称）
            # 注意：mooc-tls证书要提前创建好
            # 注意：这里好像不需要指定证书，在单独的服务上指定即可，最下面有详细的证书使用方法（如果不行再到这里也指定https证书）
            #- --default-ssl-certificate=default/mooc-tls
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

#### 六、测试 Ingress-Nginx（说明：其实就我们部署一个服务看看Ingress-Nginx能不能转发）
##### 6.1、创建测试部署文件[vi /home/kubernetes-deployment/ingress-nginx/ingress-demo.yaml]注意：如果文件内容没有格式化，可以在编辑状态下使用：:set paste 命令格式化
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
  annotations:
    # 自定义http response头信息（注意：这是为单个服务配置头信息，而不是全局的）
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "Request-Id: $req_id";
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
##### 6.2、部署测试服务，测试ingress-nginx是否可用（说明：使用部署测试服务，配置文件里面配置的ingress域名访问，看看会不会转发到当前服务上来）
```bash
$ cd /home/kubernetes-deployment/ingress-nginx

# 部署测试服务（apply表示修改或创建部署（也可以使用create代替），-f 表示指定部署配置文件）
$ kubectl apply -f ingress-demo.yaml

# 查看测试服务是否部署起来（注意：如果正常的话，请使用tomcat.mooc.com域名，访问一下看看能不能访问，可以的话说明ingress-nginx部署成功）
$ kubectl get pod -o wide
```
#### 七、单独使用Ingress-Nginx代理[vi /home/kubernetes-deployment/ingress-nginx/ingress-proxy-test.yaml]，（注意：这个只是测试ingress-nginx单独代理转发，可以不测试）
```bash
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
data:
  # 在ingress-nginx的机器上暴露一个端口30000
  # 当访问30000端口时，将代理到namespace（命名空间）为default下的Service名字为tomcat-demo，Service端口为80的服务上
  # 注意：下面这个被代理的服务我们在上面已经创建好了
  "30000": default/tomcat-demo:80  
```
```bash
# 创建代理
$ kubectl apply -f /home/kubernetes-deployment/ingress-nginx/ingress-proxy-test.yaml

# 查看命名空间ingress-nginx下，所有的configmap的配置（看看是否有我们上面创建的那个）
$ kubectl get configmap -n ingress-nginx

# 找到ingress-nginx运行的节点
$ kubectl get pods -n ingress-nginx -o wide

# 在ingress-nginx的运行节点上执行，看看是否班绑定端口30000（正常是要有的）
# 直接使用ingress-nginx运行节点的IP加30000端口正常可以访问，说明单独代理配置成功
$ netstat -ntlp
```

#### 八、修改Ingress-Nginx配置简单使用[vi /home/kubernetes-deployment/ingress-nginx/ingress-config-test.yaml]，[官网详细配置项](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/)
```bash
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
data:
  # 要修改的配置项（详细的配置项请查看官网:https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/）
  proxy-body-size: "64m"
  proxy-read-timeout: "180"
  proxy-send-timeout: "180"  
```
```bash
# 修改Ingress-Nginx配置
$ kubectl apply -f /home/kubernetes-deployment/ingress-nginx/ingress-config-test.yaml

# 到ingress-Nginx运行节点上执行（找到ingress-nginx容器）
$ docker ps | grep ingress-nginx
# 进入到ingress-nginx容器内
$ docker exec -it 339c055858b8 sh
# 找到ingress-nginx进程，并找到nginx配置文件
$ ps -ef
# 可使用 / 搜索 64m，查看配置文件是否有我们上面修改的配置项（proxy-body-size = client_max_body_size 64m;）
# 注意：ingress-nginx和nginx的配置项可能不是一一对应的
$ more /etc/nginx/nginx.conf
```

#### 九、修改Ingress-Nginx全局Header（头）信息简单使用[vi /home/kubernetes-deployment/ingress-nginx/ingress-header1-test.yaml]
```bash
apiVersion: v1
kind: ConfigMap
data:
  # 具体要添加的head（头）信息
  X-Different-Name: "true"
  X-Request-Start: t=${msec}
  X-Using-Nginx-Controller: "true"
metadata:
  # configmap的名称
  name: custom-headers
  # configmap所属的命名空间
  namespace: ingress-nginx
---
apiVersion: v1
kind: ConfigMap
data:
  # 将命名空间ingress-nginx下，名字叫custom-headers的configmap的所有配置项，添加到ingress-nginx的全局头信息里面
  # 注意：custom-headers的configmap在上面有配置
  # 注意：如果设置失败，将下面的双引号去掉，再试试
  proxy-set-headers: "ingress-nginx/custom-headers"
  add-headers: "ingress-nginx/custom-headers"
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
```
```bash
# 修改Ingress-Nginx配置
# 注意：如果修改失败（可通过ingress-nginx日志查看到是否执行成功），可将配置文件里面的"ingress-nginx/custom-headers"的双引号去掉再试一试
$ kubectl apply -f /home/kubernetes-deployment/ingress-nginx/ingress-header1-test.yaml

# 查看命名空间ingress-nginx下所有的configmap（看看有没有我们上面创建的那个custom-headers）
$ kubectl get configmap -n ingress-nginx

# 到ingress-Nginx运行节点上执行（找到ingress-nginx容器）
$ docker ps | grep ingress-nginx
# 进入到ingress-nginx容器内
$ docker exec -it 339c055858b8 sh
# 找到ingress-nginx进程，并找到nginx配置文件
$ ps -ef
# 可使用 / 搜索 proxy_set_header，查看配置文件是否有我们上面修改的配置项（proxy_set_header X-Different-Name "true";）
# 注意：ingress-nginx和nginx的配置项可能不是一一对应的
$ more /etc/nginx/nginx.conf
```
#### 十、Ingress-Nginx配置证书（使用HTTS）简单使用[vi /home/kubernetes-deployment/ingress-nginx/ingress-tls-test.yaml]
```bash
#ingress
apiVersion: extensions/v1beta1
# Ingress 相关配置
kind: Ingress
metadata:
  annotations:
    # 自定义http response头信息（注意：这是为单个服务配置头信息，而不是全局的）
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "Request-Id: $req_id";
  name: tomcat-demo
  namespace: default
spec:
  # 转发规则
  rules:
  # 配置转发域名，注意修改（当访问这个域名的时候，会自动转发到当前这个服务）
  # 注意：这个域名绑定的IP需是装有ingress-nginx的节点，如果没有公网域名，可配置主机host域名测试
  - host: tomcat.mooc.com
    http:
      paths:
      - path: /
        backend:
          # 要转发到的Service的名称（注意：这个Service要提前创建好，我们的这个Service在最上面的测试环节就已经创建好了）
          serviceName: tomcat-demo
          # 要转发到的Service的端口
          servicePort: 80
  # 证书配置
  tls:
  - hosts:
    # 证书要作用在哪些域名上
    - tomcat.mooc.com
    # 证书的名称（就是Secret的名称，注意：Secret要提前创建好）
    secretName: mooc-tls
```    
```bash 
$ mkdir -p /home/ingress-nginx-tls && cd /home/ingress-nginx-tls
# 创建证书（如果有的话就不用执行了）
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout mooc.key -out mooc.crt -subj "/CN=*.mooc.com/O=*.mooc.com"
# 创建名字叫mooc-tls的Secret（证书）
$ kubectl create secret tls mooc-tls --key mooc.key --cert mooc.crt
# 查看默认命名空间下所有的证书（注意：查看有没有我们刚刚创建的mooc-tls）
$ kubectl get secrets -o wide
# 查看证书的详细信息
$ kubectl get secret mooc-tls -o yaml

# 重新启动测试服务（一切正常的话，就可以使用https了）
$ kubectl apply -f /home/kubernetes-deployment/ingress-nginx/ingress-tls-test.yaml
```

#### 十一、Ingress-Nginx Session保持（后端多个服务，一个用户始终请求同一个同一个服务）简单使用[vi /home/kubernetes-deployment/ingress-nginx/ingress-session-test1.yaml]
```bash
#ingress
apiVersion: extensions/v1beta1
# Ingress 相关配置
kind: Ingress
metadata:
  annotations:
    # 自定义http response头信息（注意：这是为单个服务配置头信息，而不是全局的）
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "Request-Id: $req_id";
    # Session保持的配置（Session保持方式使用cookie）  
    nginx.ingress.kubernetes.io/affinity: cookie
    # Session保持的配置（Session保持生成cookie的方式）
    nginx.ingress.kubernetes.io/session-cookie-hash: sha1
    # Session保持的配置（Session保持cookie的名称）
    nginx.ingress.kubernetes.io/session-cookie-name: route
  name: tomcat-demo
  namespace: default
spec:
  # 转发规则
  rules:
  # 配置转发域名，注意修改（当访问这个域名的时候，会自动转发到当前这个服务）
  # 注意：这个域名绑定的IP需是装有ingress-nginx的节点，如果没有公网域名，可配置主机host域名测试
  - host: tomcat.mooc.com
    http:
      paths:
      - path: /
        backend:
          # 要转发到的Service的名称（注意：这个Service要提前创建好，我们的这个Service在最上面的测试环节就已经创建好了）
          serviceName: tomcat-demo
          # 要转发到的Service的端口
          servicePort: 80
```    
```bash 
# 重新启动测试服务（一切正常的话，查看Request Headers里面一项 cookie: route=1580893009.782.38.964092）
$ kubectl apply -f /home/kubernetes-deployment/ingress-nginx/ingress-session-test1.yaml
```
#### 十二、Ingress-Nginx流量切换（新旧版本同时存在，将旧版本的流量切一些到新版本上面来）简单使用
```bash
# 创建名字叫canary的命名空间（这个命名空间供下面的两个服务使用）
$ kubectl create namespace canary
# 部署服务A
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/yamls/web-canary-a.yaml
# 部署服务B
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/yamls/web-canary-b.yaml

# 查看上面的两个服务是否部署起来
$ kubectl get pods -n canary -o wide

# 将web-canary-a服务挂载到Ingress-Nginx上（测试访问：http://canary.mooc.com/host）
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/yamls/ingress-common.yaml
```
##### 12.1、将新版本web-canary-a服务，挂载到Ingress-Nginx上（注意：这个里面有切换的配置（就是会切一部份的流量到这个新版本上面来），测试访问：http://canary.mooc.com/host 看看是否有流量切换的效果）
```bash
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/yamls/ingress-weight.yaml
```
##### 12.2、使用cookie做流量定向（就是只要请求链接里面带了名字叫web-canary的cookie且值为always，流量就会转发到新版本上来），测试访问：http://canary.mooc.com/host 看看是否有流量切换的效果）
```bash
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/yamls/ingress-cookie.yaml
```
##### 12.3、使用header做流量定向（就是只要请求头里面带了web-canary且值为always，流量就会转发到新版本上来），测试访问：http://canary.mooc.com/host 看看是否有流量切换的效果）
```bash
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/yamls/ingress-header.yaml
```
##### 12.4、只要请求头或cookie里面包含web-canary且值为always，就会将流量转发到新版本上来。如果都没有就将流量的30%转发到新版本上来（测试访问：http://canary.mooc.com/host 看看是否有流量切换的效果）
```bash
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/yamls/ingress-compose.yaml
```

#### 十一、[使用模板文件的方式修改Ingress-Nginx的配置（可修改nginx参数以及头信息等等，注意：因每次修改需要重启Ingress-Nginx才会生效，故不推荐使用）](https://github.com/firechiang/kubernetes-study/tree/master/docs/ingress-nginx-build3.md)

