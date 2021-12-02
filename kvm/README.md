#### 启动default网络（注意：default网络默认不会随系统启动）
```bash
# 查看所有网络列表
$ virsh net-list --all

# 启动default网络
$ virsh net-start default

# 设置default网络自启动
$ virsh net-autostart default

# 关闭default网络
$ virsh net-destroy default
```