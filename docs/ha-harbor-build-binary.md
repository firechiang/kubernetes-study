#### 一、Harbor高可用搭建原理说明
  - 搭建多个Harbor私有仓库
  - 利用Harbor自带的同步功能做双向同步，自动将镜像同步到其它节点
  - 最后利用HA-Proxy或Nginx做负载均衡即可
  
#### 二、Harbor配置镜像同步
![image](https://github.com/firechiang/kubernetes-study/blob/master/image/harbor-001.png)
![image](https://github.com/firechiang/kubernetes-study/blob/master/image/harbor-002.png)
