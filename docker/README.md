#### 一、[Docker离线安装][1]
#### 二、[Docker在线安装（推荐使用）][2]
#### 三、[Docker基础使用][3]
#### 四、Docker Engine 组成部分
 - dockerd（Docker后台进程，核心组件）
 - REST API Server（Docker Cli命令行端和后台核心进程交互的桥梁）
 - Docker Cli（Docker命令行端）

#### 五、Docker Image 相关说明
 - Linux分为内核空间和用户空间，内核空间就是Kernel（bootfs）内核，用户空间（rootfs）就是在Kernel内核之上做了一层扩展，比如Centos，Ubuntu等系统
 - Docker Image 的 Base Image（基础镜像）就是Linux 的用户空间（rootfs），比如Centos，Ubuntu等。但不包含Linux Kernel（bootfs）内核空间
 - Docker 所有的Image（镜像）都是共享宿主机的Kernel（bootfs）内核空间，所以说Docker比虚拟机要轻量
 - Docker Image每添加一层就相当于在原来的的基础之上做了一层扩展
 - Docker Image 每一层都是Read-Only（只读）

[1]: https://github.com/firechiang/kubernetes-study/tree/master/docker/docs/docker-offline-install.md
[2]: https://github.com/firechiang/kubernetes-study/tree/master/docker/docs/docker-online-install.md
[3]: https://github.com/firechiang/kubernetes-study/tree/master/docker/docs/docker-simple-use.md
