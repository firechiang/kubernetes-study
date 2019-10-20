### 使用Kubernetes定时执行当前应用（注意：是使用k8s定时调度执行当前应用）
#### 一、构建Docker镜像并推送到仓库
```bash
$ cd /home                                                     
$ git clone https://github.com/firechiang/kubernetes-study.git
$ cd kubernetes-study/k8s-deploy/k8s-deploy-job-demo

# Maven打包
$ mvn clean package

# 构建Docker镜像，名为k8s-deploy-job-demo，版本v1。构建完成后放到当前目录
# 注意：这个命令需要Dockerfile配置文件，已经写好了，可查看
$ docker build -t k8s-deploy-job-demo:v1 .

# 运行上一步构建的容器，看看是否成功（如果成功的话会运行容器里面的应用）
$ docker run -it k8s-deploy-job-demo:v1

# 为镜像打上tag
$ docker tag k8s-deploy-job-demo:v1 server003:7079/test-service/k8s-deploy-job-demo:v1

# 推送镜像到仓库
$ docker push server003:7079/test-service/k8s-deploy-job-demo:v1
```

#### 二、创建[vi /home/k8s-deploy-job-demo.yaml]定时应用部署文件
```bash
apiVersion: batch/v1beta1
# 指定是一个定时任务，根据规则自动去执行某个容器
kind: CronJob
metadata:
  name: cronjob-demo
spec:
  # 定时任务表达式（注意：这个和Linux的corn表达式规则一样）
  schedule: "*/1 * * * *"
  # 容器正常运行结束后，不会立即删除，而是会先保留下来，最多保留3份（注意：不保留的话我们无法查看日志）
  successfulJobsHistoryLimit: 3
  # true 保存部署文件，不会开始调度，false 保存部署文件并立即开始调度
  suspend: false
  # Forbid：不允许一个JOB并发执行，当之前的JOB在没有执行结束时，不能再次执行新的JOB
  concurrencyPolicy: Forbid
  # 容器运行失败结束后，不会立即删除，而是会先保留下来，最多保留3份（注意：不保留的话我们无法查看日志）
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: cronjob-demo
        spec:
          # 容器运行失败是否要重启（注意：这个必须配置）
          restartPolicy: Never
          containers:
          - name: cronjob-demo
            # 镜像地址
            image: hub.mooc.com/kubernetes/cronjob:v1
```

#### 三、部署定时应用服务
```bash
# 部署
$ kubectl apply -f /home/k8s-deploy-job-demo.yaml

# 获取所有的定时任务，看看有没有我们刚刚部署的定时任务
$ kubectl get cronjob

# 获取所有运行的pod，看看定时应用有没有运行，以及在那台机器上运行
$ kubectl get pods -o wide

# 到对应的机器上查看定时应用运行的容器
$ docker ps -a | grep cronjob

# 查看容器运行日志，看看是否运行成功
$ docker logs <容器ID>
```