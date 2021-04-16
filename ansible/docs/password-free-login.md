```bash
# 在Ansible机器上创建SSh秘钥
$ ssh-keygen -t rsa

# 将Ansible机器上的SSh秘钥拷贝到目标部署机器上
# /root/.ssh/id_rsa.pub 是公钥所在地址
# root@192.168.122.200  是目标服务器地址
$ ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.122.200

# 测试看看是否可以免密登录
$ ssh root@192.168.122.200
```