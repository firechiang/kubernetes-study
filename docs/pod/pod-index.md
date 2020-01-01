#### 一、同一个Pod里面的容器是共享网络的，它们在启动的时候是通过pause中间容器做协调的，所以每个Pod里面都会有一个pause容器（注意：pause容器只是在Pod启动时做协调，Pod启动后pause容器将不再使用，也不占用资源）
```bash
$ kubectl create -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/docs/pod/pod-network.yaml

# 查看所有的Pod（找到Pod具体运行在哪个节点上）
$ kubectl get pods -o wide

# 到Pod的运行节点上执行，查看Pod具体运行了几个容器（注意：/pause是中间容器，每个Pod都会运行一个这样的容器，而且是最先启动的）
$ docker ps | grep pod-network

# 进入springboot-demo的容器（测试同一个Pod里面的容器是否共享网络）
$ docker exec -it 3750c040e368 sh
$ netstat -ntlp       # 会看到springboot-demo和nginx绑定的端口（正常的话都是可以看到的，因为是共享网络的）
$ wget localhost:2019 # 看看能不能访问springboot-demo的服务（正常的话是可以访问的，因为是共享网络的）
$ wget localhost:80   # 看看能不能访问nginx的服务（正常的话是可以访问的，因为是共享网络的）
```