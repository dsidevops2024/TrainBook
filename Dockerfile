#FROM openjdk:11
#COPY Hello.java /var/www/java/
#WORKDIR /var/www/java
#RUN javac Hello.java
#CMD ["java", "Hello"]
#FROM openjdk:17-slim  # Base image with OpenJDK 17 (adjust if needed)
FROM tomcat:9.0-jdk-openjdk
WORKDIR /app  # Working directory within the container
COPY staging/*.war /usr/local/tomcat/webapps/ROOT.war 
EXPOSE 8080 
#ENTRYPOINT ["java", "-jar", "/app/ROOT.war"]  
CMD ["catalina.sh", "run"]


