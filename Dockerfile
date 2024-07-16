#FROM openjdk:11
#COPY Hello.java /var/www/java/
#WORKDIR /var/www/java
#RUN javac Hello.java
#CMD ["java", "Hello"]
#FROM openjdk:17-slim  # Base image with OpenJDK 17 (adjust if needed)

#FROM openjdk:11
#WORKDIR /app  # Working directory within the container
#COPY staging/*.war /app/ROOT.war
#EXPOSE 8080 
#ENTRYPOINT ["java", "-jar", "/app/ROOT.war"]  

FROM tomcat:9.0-jdk11-openjdk-slim
# Maintainer information
LABEL maintainer="priyadarshini.mahalingam@digitalsoftwareinc.in"
# Copy the WAR file from your local machine into the container
COPY staging/*.war /usr/local/tomcat/webapps/myapp.war
# Expose the port that Tomcat is running on
EXPOSE 8080
# Start Tomcat server
CMD ["catalina.sh", "run"]


