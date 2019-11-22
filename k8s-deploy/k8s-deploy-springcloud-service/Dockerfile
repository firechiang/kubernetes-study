FROM openjdk:8-jre-alpine
COPY target/k8s-deploy-springcloud-service-0.0.1-SNAPSHOT.jar /k8s-deploy-springcloud-service-0.0.1.jar
ENTRYPOINT ["java","-jar","/k8s-deploy-springcloud-service-0.0.1.jar"]