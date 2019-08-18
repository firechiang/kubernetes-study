#### 一、安装Rancher Server-1.X（注意：这种方式服务重启之后数据就没有了，最好是挂载一个指定的数据目录），详情请查看[官方安装文档](https://www.cnrancher.com/docs/rancher/v1.x/cn/installing/installing-server/)
```bash
$ sudo docker run -d --restart=unless-stopped -p 8080:8080 rancher/server  # 下载和启动Rancher-1.X
```

#### 二、为Rancher Server添加Rancher Client（就是添加要被Rancher Server管理的服务器）
![image](https://github.com/firechiang/kubernetes-study/blob/master/rancher/image/rancher1x-use01.PNG)
![image](https://github.com/firechiang/kubernetes-study/blob/master/rancher/image/rancher1x-use02.PNG)

#### 三、添加应用（注意：应用里面包含服务，所以应用可以简单的理解为服务的分组）
![image](https://github.com/firechiang/kubernetes-study/blob/master/rancher/image/rancher1x-use03.PNG)
![image](https://github.com/firechiang/kubernetes-study/blob/master/rancher/image/rancher1x-use04.PNG)
![image](https://github.com/firechiang/kubernetes-study/blob/master/rancher/image/rancher1x-use05.PNG)
