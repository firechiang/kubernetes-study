FROM openjdk:8-jre-alpine
# 将target目录下的k8s-deploy-job-demo-0.0.1-SNAPSHOT.jar包拷贝到docker容器根目录下并将其改名为k8s-deploy-job-demo-0.0.1.jar
COPY target/k8s-deploy-job-demo-0.0.1-SNAPSHOT.jar /k8s-deploy-job-demo-0.0.1.jar
# 执行容器要执行的命令（说明：-cp 是指定jar地址）
ENTRYPOINT ["java","-cp","/k8s-deploy-job-demo-0.0.1.jar","com.firecode.k8s.deploy.job.demo.App"]