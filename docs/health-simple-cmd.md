#### 一、健康检查简单说明
 - Kubernetes默认的健康机制是只要pod里面的入口程序（pid为1的程序）不退出就认为是健康的
#### 二、以执行命令的方式进行健康检查的配置示例
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
  # 副本数一个    
  replicas: 1
  # 创建Pod的配置 
  template:
    metadata:
      labels:
        # 为Pod打上app=springboot-demo标签（如果没有这个Deployment将无法部署）
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
          # 以执行命令的方式进行健康检查 
          exec:
            command:
            - /bin/sh
            - -c
            # 只要进程存在就说明是健康的（sell命令执行完成后，退出值是0表示执行成功，非0表示执行失败）
            - ps -ef|grep java|grep -v grep
          # 容器启动后等待多少秒开始进行健康检查（单位秒），主要用于等待服务器启动好以后才进行健康检查
          initialDelaySeconds: 10
          # 健康检查的间隔时间（单位秒）
          periodSeconds: 10
          # 健康检查失败多少次，表示服务停止了（连续2次检查失败，会自动重启容器）
          failureThreshold: 2
          # 健康检查从错误到正常只需要1次，就说明服务是正常的
          successThreshold: 1
          # 执行健康检查最长的等待时间（过了这个时间表示执行失败）
          timeoutSeconds: 5
        # 以下检查通过以后才会把服务挂载到负载均衡器（pod是否启动好的探针配置）
        readinessProbe:
          # 以执行命令的方式进行健康检查 （注意：它有3种检查方式（命令，http，检查端口）建议使用http发方式验证）
          exec:
            command:
            - /bin/sh
            - -c
            # 只要进程存在就说明是健康的（sell命令执行完成后，退出值是0表示执行成功，非0表示执行失败）
            - ps -ef|grep java|grep -v grep
          # 容器启动后等待多少秒开始进行健康检查（单位秒），主要用于等待服务器启动好以后才进行健康检查
          initialDelaySeconds: 10
          # 健康检查的间隔时间（单位秒）
          periodSeconds: 10
          # 健康检查失败多少次，表示服务停止了（连续2次检查失败，会自动重启容器）
          failureThreshold: 2
          # 健康检查从错误到正常只需要1次，就说明服务是正常的
          successThreshold: 1
          # 执行健康检查最长的等待时间（过了这个时间表示执行失败）
          timeoutSeconds: 5
```
#### 三、测试健康检查
```bash
# 查看部署里面的服务是否已经能对外提供服务了
$ kubectl get deploy -n dev 
NAME              READY   UP-TO-DATE   AVAILABLE（0不能对外提供服务，1能对外提供服务）   AGE
springboot-demo   1/1     1            1                                             107s

# 查看所有部署的pod
$ kubectl get pods -n dev -o wide   

# 查看某一个pod的详细信息
# 注意查看是否有健康检查：Liveness: exec [/bin/sh -c ps -ef|grep java|grep -v grep] delay=10s timeout=5s period=10s #success=1 #failure=2
$ kubectl describe pods -n dev [部署名称（可使用上面的命令查看）]

# 进入到容器内部
$ kubectl exec -it [部署名称（可使用最上面的命令查看）] -n dev /bin/sh
$ ps -ef|grep java|grep -v grep # 测试健康检查的命令
$ echo $?                       # 查看上一条命令的执行结果（0表示执行成功，非0表示执行失败）
$ kill [服务进程ID]             # 杀手服务，正常的话应该会立即自动退出容器命令行（注意：不要-9参数）（过一会看看pod是不是已经重启了）  

# 查看pod是否有重启过
$ kubectl get pods -n dev -o wide
NAME                              READY   STATUS    RESTARTS(重启次数)   AGE
springboot-demo-98c696dd9-b5pvj   1/1     Running   1                   24m

# 查看某一个pod的详细信息（主要看看pod的重启记录（注意：不一定会有记录））
$ kubectl describe pods -n dev [部署名称（可使用上面的命令查看）]
```