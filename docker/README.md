#### 一、[Docker离线安装][1]
#### 二、[Docker在线安装（推荐使用）][2]

#### 三、配置[vi /etc/docker/daemon.json]镜像加速（注意：这个加速好像没什么用，不推荐使用）
```bash
{
  "registry-mirrors": ["https://fy707np5.mirror.aliyuncs.com"]
}

$ systemctl daemon-reload   # 重新加载配置
$ systemctl restart docker  # 重启Docker
```



[1]: https://github.com/firechiang/kubernetes-study/tree/master/docker/docs/docker-offline-install.md
[2]: https://github.com/firechiang/kubernetes-study/tree/master/docker/docs/docker-online-install.md
