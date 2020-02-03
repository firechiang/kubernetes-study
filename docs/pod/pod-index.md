#### 一、pod的状态说明
 - Pendding状态（pod还没有被调度，只是刚刚创建）
 - ContainerCreating状态（pod被调度了，找到了合适运行的机器，在该机器上拉取创建容器了）
 - Successed状态（容器启动成功了）
 - Running状态（容器正在运行中）
 - Failed状态（容器运行失败了）
 - Readdy状态（如果容器配置健康检查，健康检查通过了就是这个状态）
 - CrashLoopBackOff状态（如果容器配置健康检查，健康检查没有通过就是这个状态）
 - Unknown状态（未知状态，一般是apiServer没有收到pod的相关信息汇报）
#### 二、同一个Pod里面的容器是共享网络的，它们在启动的时候是通过pause中间容器做协调的，所以每个Pod里面都会有一个pause容器（注意：pause容器只是在Pod启动时做协调，Pod启动后pause容器将不再使用，也不占用资源）
```bash
# 注意：这个配置文件里面有容器生命周期管理和怎么修改容器里面的host文件
#（注意：修改host信息都是在pod层面修改，切记不能单独修改某个容器的host信息）
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

# 验证同一个pod里面的所有容器的host文件是一致的（这也可以验证同一个pod里面的容器是共享网络的）
# 注意：查看host信息里面是否有我们自定义的host信息（我们有指定了2个域名的ip）
#（注意：修改host信息都是在pod层面修改，切记不能单独修改某个容器的host信息）
$ docker exec -it 3750c040e368 cat /etc/hosts
$ docker exec -it 77758b51ec1f cat /etc/hosts
```

#### 三、同一个Pod里面的容器默认是共享存储目录的（注意：我们的测试pod是配置了共享存储目录的）
```bash
$ kubectl create -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/docs/pod/pod-volume.yaml

# 查看所有的Pod（找到Pod具体运行在哪个节点上）
$ kubectl get pods -o wide

# 到Pod的运行节点上执行，查看是否有/shared-volume-data目录（注意：这个是我们在配置文件里面配置的pod存储目录）
$ cd / && ls

# 到Pod的运行节点上执行，查看Pod具体运行了几个容器（注意：/pause是中间容器，每个Pod都会运行一个这样的容器，而且是最先启动的）
$ docker ps | grep pod-volume

# 先进入springboot-demo的容器，再到挂载目录/shared-web里面随便创建一个文件
$ docker exec -it 3df805a92de6 sh
$ cd shared-web
$ touch aaa           # 创建一个名为aaa的文件

# 再进入nginx的容器，再到挂载目录/shared-web里面随便创建一个文件
$ docker exec -it 77758b51ec1f sh
$ cd shared-nginx     # 进入到shared-nginx目录
$ ls                  # 看看aaa文件是否存在（正常的话aaa文件是要存在的）

# 到Pod的运行节点上执行，查看/shared-volume-data目录里面是否有aaa文件
$ cd / && ls
```

#### 四、pod在创建时apiServer可以将指定数据（文件、配置信息）交给pod，供pod里面的容器直接使用
 - 验证apiServer将密钥信息分发给了所有的pod（以保证pod可以和apiServer通信）
```bash
$ kubectl get secret  # 查看所有的secret（密钥信息）
# 查看secret的数据（secret的数据应该是通过base64加密过的）（注意：default-token-hbrwd是secretd的名字，通过上面的命令可以看到）
$ kubectl get secret default-token-hbrwd -o yaml

# 查看所有的pod
$ kubectl get pods -o wide
# 查看某个pod的详细配置（注意：pod-network是pod的名字，通过上面的命令可以看到）
# 注意：查看配置里面有一项volumes的配置，它使用的是default-token-hbrwd，而default-token-hbrwd就是密钥信息
# 注意：可以看到每个容器里面的volumeMounts都挂载了一个/var/run/secrets/kubernetes.io/serviceaccount目录（这里面放的就是密钥信息）
$ kubectl get pod pod-network -o yaml

# 到pod的运行节点执行，进入到pod里面的某个容器，查看pod和apiServer通信时所使用的密钥信息（这个密钥应该是解密base64以后的数据）
$ docker exec -it a260ccca5fc0 sh
$ cd /var/run/secrets/kubernetes.io/serviceaccount && ls
```

 - 通过apiServer将自定义的密钥信息分发给pod，以供pod里面的容器直接使用（注意：这个一般用于数据库密码的分发。配置是可以动态修改的）
```bash
# 创建自定义的secret（密钥）数据
$ kubectl create -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/docs/pod/pod-secret.yaml
# 获取所有的secret（密钥）信息，看看有没有我们上面创建的那个
$ kubectl get secrets 
# 获取我们上面创建那个secret（密钥）信息的详细数据
$ kubectl get secret dbpass -o yaml

# pod使用secret（密钥）数据
# 创建pod里面有使用secret（密钥）数据的配置
$ kubectl create -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/docs/pod/pod-use-secret.yaml
# 获取到所有的pod（注意找到pod的运行节点）
$ kubectl get pods -o wide
# 查看pod的详细配置（注意：找到volumeMounts配置项，是否有配置挂载目录/db-secret。正常是会有的）
$ kubectl get pod pod-secret -o yaml
# 到pod的运行节点执行，进入到pod里面的某个容器（注意：找到我们自定义的secret（密钥）数据）
$ docker exec -it bb42f1b8018b sh
$ cd /db-secret && ls
# 查看密码和用户名（注意：-n表示使用base64解密）
$ cat -n passwd
$ cat -n username
```

 - 通过apiServer将自定义的配置文件分发给pod，以供pod里面的容器直接使用（注意：这个一般用于不需要加密的配置信息分发。配置是可以动态修改的）
```bash
# 创建configmap配置文件（注意：test-config是配置信息的名字，可以随便起）
$ kubectl create configmap test-config --from-file https://raw.githubusercontent.com/firechiang/kubernetes-study/master/docs/pod/game.properties
# 查看所有的configmap配置（注意：看看有没有上面创建的test-config）
$ kubectl get configmaps
# 查看我们上面创建的configmap的配置的详细信息
$ kubectl get configmap test-config -o yaml
# 修改configmap的配置信息（可以用这个命令替代vi）（注意：test-config是要修改的configmap的名称）
$ kubectl edit cm test-config

# 创建pod里面有使用test-config配置文件（具体可查看创建pod的配置文件）
$ kubectl create -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/docs/pod/pod-game.yaml
# 获取到所有的pod（注意找到pod的运行节点）
$ kubectl get pods -o wide
# 查看pod的详细配置（注意：找到volumeMounts配置项，是否有配置挂载目录/etc/config/game。正常是会有的）
$ kubectl get pod pod-game -o yaml
# 到pod的运行节点执行，进入到pod里面的某个容器（注意：找到我们自定义的game.properties配置文件）
$ docker exec -it 00c80fbdf425 sh
$ cd /etc/config/game && ls
# 查看配置文件里面的数据
$ cat game.properties
```

 - 通过apiServer将自定义的配置信息分发给pod，以供pod里面的容器直接使用（注意：这个一般用于不需要加密的配置信息分发。配置是可以动态修改的）
```bash
# 创建configmap配置信息
$ kubectl create -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/docs/pod/configmap.yaml
# 查看所有的configmap配置（注意：看看有没有上面创建的config-test）
$ kubectl get configmaps
# 查看我们上面创建的configmap的配置的详细信息
$ kubectl get configmap config-test -o yaml
# 修改configmap的配置信息（可以用这个命令替代vi）（注意：config-test是要修改的configmap的名称）
$ kubectl edit cm config-test

# 创建pod里面有将configmap的配置的值，传递给pod容器作为容器的环境变量（具体可查看创建pod的配置文件）
$ kubectl create -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/docs/pod/pod-env.yaml
# 获取到所有的pod（注意找到pod的运行节点）
$ kubectl get pods -o wide
# 查看pod的详细配置（注意：查看是否环境变量LOG_LEVEL_CONFIG的配置。正常是会有的）
$ kubectl get pod pod-env -o yaml
# 到pod的运行节点执行，进入到pod里面的某个容器
$ docker exec -it 3be5bdf82768 sh
# 查看环境变量是否已经设置好
$ env|grep LOG_LEVEL_CONFIG
```

 - 通过apiServer获取到pod的相关信息，供pod里面的容器直接使用
```bash
# 创建pod（注意：里面有如何取到pod本身的相关信息，供pod里面的容器使用）
$ kubectl create -f https://raw.githubusercontent.com/firechiang/kubernetes-study/master/docs/pod/pod-downwardapi.yaml
# 获取到所有的pod（注意找到pod的运行节点）
$ kubectl get pods -o wide
# 到pod的运行节点执行，进入到pod里面的某个容器
$ docker exec -it 2e4c601597a6 sh
# 查看是否有共享信息
$ cd /etc/podinfo && ls
$ cat -n labels
```