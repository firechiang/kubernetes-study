#### [Dubbo注解搭建示例](https://github.com/apache/dubbo-samples/tree/master/dubbo-samples-annotation)
#### 测试Dubbo服务是否正常运行
```bash
$ telnet 127.0.0.1 20880                         # 连接Dubbo服务
$ ls                                             # 查看Dubbo所有服务
$ ls xxx.xxx.DemoService                         # 查看DemoService的所有方法
$ invoke xxx.xxx.DemoService.serviceName("test") # 调用DemoService的serviceName函数并传了String 参数 test
```
