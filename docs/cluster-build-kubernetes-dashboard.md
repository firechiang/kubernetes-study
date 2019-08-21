### 部署Kubernetes-Dashboard（注意：所有命令都在主节点执行）
#### 一、创建部署文件，[官方部署文档](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#deploying-the-dashboard-ui)，[官方部署文件(不建议使用)](https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml)，[git源码地址（里面有版本信息）](https://github.com/kubernetes/dashboard)
```bash
$ mkdir -p /etc/kubernetes/addons && cat > /etc/kubernetes/addons/dashboard-all.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    k8s-app: kubernetes-dashboard
    # Allows editing resource and makes sure it is created first.
    addonmanager.kubernetes.io/mode: EnsureExists
  name: kubernetes-dashboard-settings
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
    addonmanager.kubernetes.io/mode: Reconcile
  name: kubernetes-dashboard
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubernetes-dashboard
  namespace: kube-system
  labels:
    k8s-app: kubernetes-dashboard
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
        seccomp.security.alpha.kubernetes.io/pod: 'docker/default'
    spec:
      priorityClassName: system-cluster-critical
      containers:
      - name: kubernetes-dashboard
        # 指定镜像地址
        image: registry.cn-hangzhou.aliyuncs.com/google_containers/kubernetes-dashboard-amd64:v1.10.1
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 50m
            memory: 100Mi
        ports:
        - containerPort: 8443
          protocol: TCP
        args:
          # PLATFORM-SPECIFIC ARGS HERE
          - --auto-generate-certificates
        volumeMounts:
        - name: kubernetes-dashboard-certs
          mountPath: /certs
        - name: tmp-volume
          mountPath: /tmp
        livenessProbe:
          httpGet:
            scheme: HTTPS
            path: /
            port: 8443
          initialDelaySeconds: 30
          timeoutSeconds: 30
      volumes:
      - name: kubernetes-dashboard-certs
        secret:
          secretName: kubernetes-dashboard-certs
      - name: tmp-volume
        emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Exists"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    k8s-app: kubernetes-dashboard
    addonmanager.kubernetes.io/mode: Reconcile
  name: kubernetes-dashboard-minimal
  namespace: kube-system
rules:
  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs"]
  verbs: ["get", "update", "delete"]
  # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["kubernetes-dashboard-settings"]
  verbs: ["get", "update"]
  # Allow Dashboard to get metrics from heapster.
- apiGroups: [""]
  resources: ["services"]
  resourceNames: ["heapster"]
  verbs: ["proxy"]
- apiGroups: [""]
  resources: ["services/proxy"]
  resourceNames: ["heapster", "http:heapster:", "https:heapster:"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
  labels:
    k8s-app: kubernetes-dashboard
    addonmanager.kubernetes.io/mode: Reconcile
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubernetes-dashboard-minimal
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
---
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
    # Allows editing resource and makes sure it is created first.
    addonmanager.kubernetes.io/mode: EnsureExists
  name: kubernetes-dashboard-certs
  namespace: kube-system
type: Opaque
---
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
    # Allows editing resource and makes sure it is created first.
    addonmanager.kubernetes.io/mode: EnsureExists
  name: kubernetes-dashboard-key-holder
  namespace: kube-system
type: Opaque
---
apiVersion: v1
kind: Service
metadata:
  name: kubernetes-dashboard
  namespace: kube-system
  labels:
    k8s-app: kubernetes-dashboard
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  selector:
    k8s-app: kubernetes-dashboard
  ports:
  - port: 443
    targetPort: 8443
    nodePort: 30005
  type: NodePort
EOF  
```

#### 二、部署 Kubernetes-Dashboard（注意：以下命令在主节点上执行）
```bash
# 创建和部署服务
$ kubectl apply -f /etc/kubernetes/addons/dashboard-all.yaml

# 查看kubernetes-dashboard部署状态（-n是指定namespace）
$ kubectl get deployment kubernetes-dashboard -n kube-system
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-dashboard   1/1     1            1           4m27s

# 查看kube-system下所有pod的详细信息（里面有运行状态信息）
$ kubectl --namespace kube-system get pods -o wide
NAME                                      READY   STATUS    RESTARTS   AGE     IP               NODE        NOMINATED NODE   READINESS GATES
calico-kube-controllers-f9dbcb664-t9p67   1/1     Running   0          130m    172.22.81.195    server006   <none>           <none>
calico-node-2r7xg                         1/1     Running   0          122m    192.168.83.145   server008   <none>           <none>
calico-node-4wg5h                         1/1     Running   0          130m    192.168.83.143   server006   <none>           <none>
calico-node-klr6n                         1/1     Running   0          127m    192.168.83.144   server007   <none>           <none>
calico-typha-649d9968df-rsxp9             1/1     Running   0          130m    192.168.83.145   server008   <none>           <none>
coredns-8686dcc4fd-4s8lw                  1/1     Running   0          132m    172.22.81.194    server006   <none>           <none>
coredns-8686dcc4fd-s6r54                  1/1     Running   0          132m    172.22.81.193    server006   <none>           <none>
etcd-server006                            1/1     Running   0          131m    192.168.83.143   server006   <none>           <none>
etcd-server007                            1/1     Running   0          127m    192.168.83.144   server007   <none>           <none>
kube-apiserver-server006                  1/1     Running   0          131m    192.168.83.143   server006   <none>           <none>
kube-apiserver-server007                  1/1     Running   0          127m    192.168.83.144   server007   <none>           <none>
kube-controller-manager-server006         1/1     Running   1          131m    192.168.83.143   server006   <none>           <none>
kube-controller-manager-server007         1/1     Running   1          127m    192.168.83.144   server007   <none>           <none>
kube-proxy-bg457                          1/1     Running   0          127m    192.168.83.144   server007   <none>           <none>
kube-proxy-m5hc7                          1/1     Running   0          132m    192.168.83.143   server006   <none>           <none>
kube-proxy-n5bd4                          1/1     Running   0          122m    192.168.83.145   server008   <none>           <none>
kube-scheduler-server006                  1/1     Running   2          131m    192.168.83.143   server006   <none>           <none>
kube-scheduler-server007                  1/1     Running   0          127m    192.168.83.144   server007   <none>           <none>
kubernetes-dashboard-7d5f7c58f5-qv6vb     1/1     Running   0          4m40s   172.22.150.195   server008   <none>           <none>

# 查看kube-system下所有service的详细信息，（-n是指定namespace）
$ kubectl get services kubernetes-dashboard -n kube-system -o wide
NAME                   TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE   SELECTOR
kubernetes-dashboard   NodePort   10.96.115.46   <none>        443:30005/TCP   99m   k8s-app=kubernetes-dashboard

# 查看30005端口是否绑定在主机上（注意：端口是通过查看service信息得到的，后面的30005是绑定在节点机器上的，前面的443是绑定在容器里面）
$ netstat -ntlp|grep 30005
```

#### 三、配置Kubernetes-Dashboard HTTS证书（注意：Kubernetes-Dashboard部署默认是没有HTTS证书的，浏览器访问会报错）
```bash
# 定位证书目录
$ mkdir -p /etc/kubernetes/addons/dashboard-secret && cd /etc/kubernetes/addons/dashboard-secret

# 生成证书(如果已经有证书了，就不需要生成了)
$ openssl genrsa -out dashboard.key 2048
$ openssl req -new -out dashboard.csr -key dashboard.key -subj '/CN=server006'
# 证书加密方式：sha256，有效天数：365
$ openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt

# 配置证书（注意：证书就两个文件，一个.key文件，一个.crt文件）
# 删除名字为kubernetes-dashboard-certs的证书secret（注意：这个名字使我们在部署文件中配置的）
$ kubectl delete secret kubernetes-dashboard-certs -n kube-system
# 配置新的证书secret
$ kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kube-system

# 要重启Kubernetes-Dashboard证书才能生效
# 查看 pod
$ kubectl get pod -n kube-system
# 重启 pod（注意：这个删除就是重启，因为我们不是删deployment）
$ kubectl delete pod <pod name> -n kube-system
```

#### 四、访问和登陆Kubernetes-Dashboard，它默认只支持 token 认证登陆，所以如果使用 KubeConfig 文件，需要在该文件中指定 token。所以我们直接使用token的方式登录（访问地址：https://NodeIP:30005）
![image](https://github.com/firechiang/kubernetes-study/blob/master/image/kubernetes-dashboard-login-token.JPG)
```bash
# 创建一个Service Account，它的名字叫dashboard-admin
$ kubectl create sa dashboard-admin -n kube-system

# 创建角色绑定关系（将集群角色cluster-admin的权限赋给我们刚刚创建的dashboard-admin）
$ kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin

# 查看dashboard-admin的secret名字
$ ADMIN_SECRET=$(kubectl get secrets -n kube-system | grep dashboard-admin | awk '{print $1}') && echo $ADMIN_SECRET

# 打印secret的token（注意：复制这个token去登陆即可）
$ kubectl describe secret -n kube-system ${ADMIN_SECRET} | grep -E '^token' | awk '{print $2}'
```
