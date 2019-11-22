### 传统的Web项目部署
```bash
$ mvn clean package

# 查看jar包里面的文件和目录
$ jar -tf k8s-deploy-dubboxml-web-0.0.1-SNAPSHOT.war      

# 创建目录
$ mkdir ROOT   

# 移动文件                        
$ mv k8s-deploy-dubboxml-web-0.0.1-SNAPSHOT.war ROOT/
$ cd ROOT

# 解压jar文件到当前目录
$ jar -xvf k8s-deploy-dubboxml-web-0.0.1-SNAPSHOT.war
$ cd ../

# 构建Docker镜像（.表示Dockerfile在当前目录）
$ docker build -t k8s-deploy-dubboxml-web:0.0.1 .

# 为镜像打上tag
$ docker tag k8s-deploy-dubboxml-web:0.0.1 server003:7079/test-service/k8s-deploy-dubboxml-web:0.0.1

# 推送镜像到仓库
$ docker push server003:7079/test-service/k8s-deploy-dubboxml-web:0.0.1

# Kubernetes部署
$ kubectl apply -f deployment.yml
```