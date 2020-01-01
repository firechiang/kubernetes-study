#### 一、Pod选择其实是要和哪些Pod部署在一起，运行在同一个节点上
#### 二、配置示例
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springboot-demo-pod
  namespace: dev
spec:
  selector:
    matchLabels:
      app: springboot-demo-pod
  replicas: 1
  template:
    metadata:
      labels:
        app: springboot-demo-pod
    spec:
      containers:
      - name: springboot-demo-pod
        image: chiangfire/springboot-demo:20191122051537
        ports:
        - containerPort: 2019
      # 选择匹配的配置
      affinity:
        # Pod的反亲和性配置（就是不要和哪些pod部署在一起，主要用于多实列部署，不要跑在同一台机器上）
        #podAntiAffinity:
        # Pod的亲和配置（就是要和哪些pod部署在一起，运行在同一个节点上）
        podAffinity:
          # 必须要满足的条件的配置
          requiredDuringSchedulingIgnoredDuringExecution:
          # label选择（注意：如果有多个labelSelector它们是或的关系，就是只要满足一个就可以调度）
          - labelSelector:
              # 匹配表达式（注意：如果有多个matchExpressions，它们是并且的关系，就是在同一个label选择器下都要都满足才能调度）
              matchExpressions:
              # 要选择的label的key
              - key: app
                # 匹配模式
                operator: In
                values:
                # 要匹配的值
                - springboot-demo
            topologyKey: kubernetes.io/hostname
          # 优先选择的配置（就是如果Pod满足以下条件，就优先选择） 
          preferredDuringSchedulingIgnoredDuringExecution:
          # 条件权重（权重越大越优先选择），可以有多个（每个权重都有权重下面的特性）
          - weight: 100
            # 特性 
            podAffinityTerm:
              # label选择
              labelSelector:
                matchExpressions:
                # 匹配表达式
                - key: app
                  # 匹配模式
                  operator: In
                  values:
                  # 要匹配的值
                  - springboot-demo-node
              topologyKey: kubernetes.io/hostname
```