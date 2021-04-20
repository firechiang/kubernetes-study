#### OpenSUSE安装VMWare 16
##### 一、安装相关依赖
```bash
# 安装源码编译工具
$ sudo zypper in gcc gcc-c++
# 安装内核源码（VMWare需要Kernel内核源码头文件）
$ sudo yast2 -i kernel-source
```

##### 二、安装VMware 16
```bash
# 给从官方下载的VMware添加执行权限
$ chmod +x VMware-Workstation-Full-16.1.1-17801498.x86_64.bundle
# 安装VMware
$ sudo ./VMware-Workstation-Full-16.1.1-17801498.x86_64.bundle
```

#### 三、永久激活秘钥
```bash
ZF3R0-FHED2-M80TY-8QYGC-NPKYF
YF390-0HF8P-M81RQ-2DXQE-M2UT6
ZF71R-DMX85-08DQY-8YMNC-PPHV8
```