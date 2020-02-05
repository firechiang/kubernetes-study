#### 一、修改nginx-ingress-controlle的配置文件[vi /home/kubernetes-deployment/ingress-nginx/nginx-ingress-controlle.yaml]
```bash
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
          # 共享信息配置 （注意：这个就是用来存储ingress-nginx配置模板文件的）
          volumeMounts:
          # 信息挂载目录
          - mountPath: /etc/nginx/template
            # 要读取的共享信息的名字（注意：这个名字叫nginx-template-volume的共享信息我们在后面配置好了）
            name: nginx-template-volume
            readOnly: true   
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
      # 共享信息（注意：在这里面主要是用来存储ingress-nginx的配置信息）            
      volumes:
      # 共享信息的名称（这个名称可以随便起）
      - name: nginx-template-volume
        configMap:
	  # 要读取的configmap的名称（注意：这个configmap要提前创建好） 
	  name: nginx-template
	  items:
	  # 要读取的configmap的key
	  - key: nginx.tmpl
	    # 要读取的configmap的文件所在路径
	    path: nginx.tmpl              
```
#### 二、修改nginx-ingress-controlle的部署信息（注意：一定是先部署好了ingress-nginx，拿着上面的配置文件来修改，而不是拿着上面的配置文件来部署ingress-nginx）
```bash
# 找到ingress-nginx运行节点
$ kubectl get pods -n ingress-nginx -o wide

# 到ingress-nginx运行节点执行，找到ingress-nginx容器
$ docker ps | grep ingress-nginx

# 将ingress-nginx容器里面的文件nginx.tmpl模板文件，复制到当前目录
$ docker cp 846db713c2f7:/etc/nginx/template/nginx.tmpl ./

# 将nginx.tmpl模板文件发送到主节点
$ scp ./nginx.tmpl root@server001:/home

# 创建名字叫nginx-template的configmap（-n是指定命名空间）
$ kubectl create configmap nginx-template --from-file ./nginx.tmpl -n ingress-nginx

# 查看命名空间ingress-nginx下所有的configmap（注意看看有没有我们上面创建名字叫nginx-template的configmap）
$ kubectl get configmap -n ingress-nginx

# 查看名字叫nginx-template的configmap的详细配置
$ kubectl get configmap nginx-template -n ingress-nginx -o yaml

```
