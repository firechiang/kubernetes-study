#### 一、Resources简要说明
 - Requests 表示容器希望被分配到多大的内存和CPU
 - Limits 表示容器所能使用资源的上限
 
#### 二、部署限制资源的容器
```bash
$ kubectl apply -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/yamls/springboot-demo-dev.yaml
```