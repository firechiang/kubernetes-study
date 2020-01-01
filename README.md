#### 一、[Kubeadm方式搭建Kubernetes集群][1]
#### 二、[安装包的方式搭建Kubernetes集群（推荐使用）][4]
#### 三、[简单测试集群的可用性][2]
#### 四、[Kubernetes-Dashboard部署和简单使用（不推荐使用，建议使用RanCher）][3]
#### 五、[Ingress（浏览器访问集群服务的桥梁，就是代理转发）部署（推荐使用）][7]
#### 六、[私有镜像仓库Harbor单节点离线安装（推荐生产使用）][5]
#### 七、[私有镜像仓库Harbor双主同步复制高可用离线安装][6]
#### 八、[Kubernetes定时调度执行容器简单使用][8]
#### 九、[Namespace（命名空间）简单使用和说明][9]
#### 十、[Resources（资源限制）简单使用和说明][10]
#### 十一、[Label（标签）简单使用和说明][11]
#### 十二、[Taint（污点<给Node加上特殊的标记，让Pod不能自动部署到该Node（节点）上，除非Pod容忍该污点才能部署在该节点上>）简单使用和说明][14]
#### 十三、[部署时选择指定Node（节点）简单使用和说明][12]
#### 十四、[部署时想和指定Pod部署在一起或多实列不要部署在同一台机器上简单使用和说明][13]
#### 十五、[健康检查和验证服务是否启动成功才对外提供服务（执行命令的方式）简单使用][15]
#### 十六、[健康检查和验证服务是否启动成功才对外提供服务（HTTP请求的方式）简单使用][16]
#### 十七、[健康检查和验证服务是否启动成功才对外提供服务（TCP的方式（检查端口是否处于监听状态））简单使用][17]
#### 十八、[创建部署（先将原有的服务杀掉重新部署）简单使用（不推荐生产使用）][18]


[1]: https://github.com/firechiang/kubernetes-study/tree/master/docs/cluster-build-kubeadm.md
[2]: https://github.com/firechiang/kubernetes-study/tree/master/docs/cluster-test-simple.md
[3]: https://github.com/firechiang/kubernetes-study/tree/master/docs/cluster-build-kubernetes-dashboard.md
[4]: https://github.com/firechiang/kubernetes-study/tree/master/docs/cluster-build-binary.md
[5]: https://github.com/firechiang/kubernetes-study/tree/master/docs/single-harbor-build-binary.md
[6]: https://github.com/firechiang/kubernetes-study/tree/master/docs/ha-harbor-build-binary.md
[7]: https://github.com/firechiang/kubernetes-study/tree/master/docs/ingress-nginx-build.md
[8]: https://github.com/firechiang/kubernetes-study/blob/master/k8s-deploy/k8s-deploy-job-demo/README.md
[9]: https://github.com/firechiang/kubernetes-study/tree/master/docs/namespace-simple.md
[10]: https://github.com/firechiang/kubernetes-study/tree/master/docs/resources-simple.md
[11]: https://github.com/firechiang/kubernetes-study/tree/master/docs/label-simple.md
[12]: https://github.com/firechiang/kubernetes-study/tree/master/docs/deploy-select-node.md
[13]: https://github.com/firechiang/kubernetes-study/tree/master/docs/deploy-select-pod.md
[14]: https://github.com/firechiang/kubernetes-study/tree/master/docs/deploy-select-taint.md
[15]: https://github.com/firechiang/kubernetes-study/tree/master/docs/health-simple-cmd.md
[16]: https://github.com/firechiang/kubernetes-study/tree/master/docs/health-simple-http.md
[17]: https://github.com/firechiang/kubernetes-study/tree/master/docs/health-simple-tcp.md
[18]: https://github.com/firechiang/kubernetes-study/tree/master/docs/deploy-simple-recreate.md


