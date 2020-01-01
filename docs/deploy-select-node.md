#### 一、配置示例
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springboot-demo
  namespace: dev
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
        - containerPort: 2019
      # 选择匹配的配置
      affinity:
        # Node（节点）的反亲和性配置（就是不要部署在哪些机器上）
        #nodeAntiAffinity:
        # Node（节点）的亲和性配置 （要部署在哪些Node（节点）上）
        nodeAffinity:
          # 必须要满足的条件的配置
          requiredDuringSchedulingIgnoredDuringExecution:
            # 节点的选择策略（注意：如果有多个nodeSelectorTerms它们是或的关系，就是只要满足一个就可以调度）
            nodeSelectorTerms:
            # 匹配表达式（注意：如果有多个matchExpressions，它们是并且的关系，就是在同一个策略下都要都满足才能调度）
            - matchExpressions:
              # 要选择的label的key （注意：beta.kubernetes.io/arch是Kubernetes原生自带的，表示当前节点cpu的架构）
              - key: beta.kubernetes.io/arch
                # 匹配模式 
                operator: In
                # 要匹配的值（amd64表示cpu的架构）
                values:
                - amd64
          # 优先选择的配置（就是如果Node（节点）满足以下条件，就将服务优先部署在该Node（节点）上）      
          preferredDuringSchedulingIgnoredDuringExecution:
          # 条件权重（权重越大越优先选择），可以有多个（每个权重都有权重下面的特性）
          - weight: 1
            # 特性 
            preference:
              # 匹配表达式 
              matchExpressions:
              # 要选择的label的key （注意：disktype是Kubernetes原生自带的，表示当前节点的磁盘类型）
              - key: disktype
                # 匹配模式 
                operator: NotIn
                values:
                # 要匹配的值（ssd表示表示固态硬盘）
                - ssd
```