#### 一、Resources简要说明
 - Requests 表示容器希望被分配到多大的内存和CPU
 - Limits 表示容器所能使用资源的上限
 - 如果部署时设置Requests == Limits两个值相等，表示服务是可靠的，等级最高，最不容易被kill掉
 - 如果部署时设置Requests != Limits两个值不相等，表示服务是比较可靠的，等级居中
 - 如果部署时没有设置资源情况，表示服务是不可靠的，等级最低，当资源不够用时，容器可能被直接kill掉
```bash
$ kubectl get nodes                # 查看Kubernetes集群所有的从节点
$ kubectl describe node server002  # 查看节点详细信息（包括每个服务所占用的资源情况，server002是节点的名称）
```
 
#### 二、部署限制资源的容器
```bash
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/yamls/springboot-demo-dev.yaml
$ kubectl get pods -n dev -o wide # 查看上面的服务部署在那个节点上
$ kubectl describe node server004 # 查看节点详细信息（包括每个服务所占用的资源情况，server002是节点的名称）
$ docker inspect 8e7911acaaa1     # 查看容器参数的设置，可以看到资源限制（8e7911acaaa1是容器运行的ID）
$ docker stats 8e7911acaaa1       # 查看容器资源使用情况（8e7911acaaa1是容器运行的ID）
```

#### 三、创建 [vi test-limits.yaml] 一个资源限制和校验范围的配置文件（用于校验部署文件里面的资源限制是否合理，如果不合理将无法部署）
```bash
apiVersion: v1
# 资源范围限制
kind: LimitRange
metadata:
  # 资源范围限制的名称
  name: test-limits
spec:
  limits:
    # 容器所能使用的资源最大限制（1核CPU=1000m）  
  - max:
      cpu: 4000m
      memory: 2Gi
    # 容器所能使用的资源最小限制（1核CPU=1000m）    
    min:
      cpu: 100m
      memory: 100Mi
    maxLimitRequestRatio:
      # 同一个配置里面CPU的Limits最大值可以比Requests的大3倍
      cpu: 3
      # 同一个配置里面Memory的Limits最大值可以比Requests的大2倍
      memory: 2
    # 以上对对pod的资源限制
    type: Pod
  - default:
      cpu: 300m
      memory: 200Mi
    defaultRequest:
      cpu: 200m
      memory: 100Mi
    max:
      cpu: 2000m
      memory: 1Gi
    min:
      cpu: 100m
      memory: 100Mi
    maxLimitRequestRatio:
      cpu: 5
      memory: 4
    # 以上对Container（容器）默认的资源限制
    type: Container
```

#### 四、创建上面的资源限制和范围校验（-n是指定Namespace）
```bash
$ kubectl create ns test-limit-range                      # 创建一个Namespace名字叫test-limit-range
$ kubectl create -f  test-limits.yaml -n test-limit-range # 创建上面的资源限制和范围校验
$ kubectl describe limits -n test-limit-range             # 查看某个命名空间下的所有资源限制（看看是不是和我们上面配置文件里面的一样）
$ kubectl get limitranges -n test-limit-range             # 获取所有的资源限制和范围校验（看看有没有我们上面创建的那个）
```

#### 五、创建 [vi springboot-demo-limit.yaml] 资源限制范围和校验部署文件（-n是指定Namespace）
```bash
#deploy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springboot-demo
  # 指定Namespace（因为这个Namespace里面配置了资源限制和校验，所以只要是部署在这个Namespace下服务，就会校验和配置资源限制）
  namespace: test-limit-range
spec:
  selector:
    matchLabels:
      app: springboot-demo
  replicas: 1
  template:
    metadata:
      labels:
        app: springboot-demo
    spec:
      containers:
      - name: springboot-demo
        image: chiangfire/springboot-demo:20191122051537
        ports:
        # 注意：这个端口要和服务本身启动起来的端口相同
        - containerPort: 2019
```
#### 六、部署测试
```bash
$ kubectl apply -f springboot-demo-limit.yaml
# 获取test-limit-range Namespace下所有的部署
$ kubectl get deployments -n test-limit-range
# 获取名字叫springboot-demo的部署的详细配置信息
$ kubectl get deployment springboot-demo -n test-limit-range -o yaml
# 获取test-limit-range Namespace下所有的pod
$ kubectl get pods -n test-limit-range
# 获取名字叫springboot-demo-f8b845dfc-zck96的pod的详细配置信息
# 注意：查看是否有资源限制（如果不能部署里面也会有错误信息）
$ kubectl get pod springboot-demo-f8b845dfc-zck96 -n test-limit-range -o yaml
```

#### 七、资源配额简单使用（就是为整个Namespace配置资源额度）
##### 7.1 创建 [vi resource-quota.yaml] 资源配额配置文件
```bash
apiVersion: v1
kind: ResourceQuota
metadata:
  name: resource-quota
spec:
  hard:
    # 整个Namespace下最多允许4个Pod
    pods: 4
    # 整个Namespace需要被分配到2核CPU
    requests.cpu: 2000m
    # 整个Namespace需要被分配到4G内存
    requests.memory: 4Gi
    # 整个Namespace最多能使用4核CPU
    limits.cpu: 4000m
    # 整个Namespace最多能使用8G内存
    limits.memory: 8Gi
    ####################################
    # 整个Namespace下最多允许10个configmap
    configmaps: 10
    persistentvolumeclaims: 4
    # 整个Namespace下最多允许20个副本
    replicationcontrollers: 20
    secrets: 10
    # 整个Namespace下最多允许10个service
    services: 10
```

##### 7.2 创建资源配额配
```bash
# 创建Namspace名字叫resource-quota-test
$ kubectl create ns resource-quota-test 
# 为名字叫resource-quota-test的Namespace创建资源配额
$ kubectl apply -f resource-quota.yaml -n resource-quota-test
# 查看名字叫resource-quota-test的Namespace下的所有资源配额
$ kubectl get quota -n resource-quota-test
# 查看名字叫resource-quota-test的Namespace的资源配额的详细信息
# 注意：查看未使用的是不是和上面配置文件里面的信息一样
$ kubectl describe quota -n resource-quota-test
```
##### 7.3 使用资源配额度（指定这个Namespace即可）

#### 八、Pod Eviction（就是当资源不够用了的时候，杀死那些Pod）驱逐策略
 - 磁盘紧缺的时候Kubernetes会删除死掉的Pod和容器以及没有用的镜像
 - 内存紧缺的时候Kubernetes会杀死不可靠的且占用内存最大的Pod（就是没有配置资源的部署，也是按照Pod的等级从低到高开始杀（最上面有Pod的等级说明））
##### 8.1 策略一（节点的机器内存小于1.5G并且持续了1分30秒时可能触发杀手Pod（注意：不一定会触发））
```bash
--eviction-soft=memory.available<1.5Gi
--eviction-soft-grace-period=memory.available=1m30s
```
##### 8.2 策略二（节点的机器内存小于100M或者磁盘小于1Gi或者负载小于5%，立刻触发Pod Eviction，开始杀Pod（注意：是立刻触发）
```bash
--eviction-hard=memory.available<100Mi,nodefs.available<1Gi,nodefs.inodesFree<5%
```
##### 8.3 策略如何配置请自行百度