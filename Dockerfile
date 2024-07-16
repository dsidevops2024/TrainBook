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

#FROM tomcat:9.0-jdk11-openjdk-slim
# Maintainer information
#LABEL maintainer="priyadarshini.mahalingam@digitalsoftwareinc.in"
# Copy the WAR file from your local machine into the container
#COPY staging/*.war /usr/local/tomcat/webapps/myapp.war
# Expose the port that Tomcat is running on
#ENTRYPOINT ["java", "-jar", "/app/ROOT.war"]
#EXPOSE 8080
# Start Tomcat server
#CMD ["catalina.sh", "run"]

FROM mcr.microsoft.com/openjdk:jdk-11-windowsservercore-ltsc2019
# Set environment variables
ENV CATALINA_HOME="C:\\tomcat"
ENV PATH="%CATALINA_HOME%\\bin;%PATH%"
 
# Download and extract Tomcat
RUN powershell -Command `
    $ErrorActionPreference = 'Stop'; `
Invoke-WebRequest -Uri https://downloads.apache.org/tomcat/tomcat-9/v9.0.65/bin/apache-tomcat-9.0.65-windows-x64.zip -OutFile C:\tomcat.zip; `
Expand-Archive -Path C:\tomcat.zip -DestinationPath C:\; `
Rename-Item -Path C:\apache-tomcat-9.0.65 -NewName 'tomcat'; `
Remove-Item -Path C:\tomcat.zip
 
# Expose the port Tomcat is running on
EXPOSE 8080
 
# Start Tomcat
CMD ["catalina.bat", "run"]
