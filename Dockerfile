FROM openjdk:11
COPY Hello.java /var/www/java/
WORKDIR /var/www/java
RUN javac Hello.java
CMD ["java", "Hello"]
#FROM openjdk:17-slim  # Base image with OpenJDK

#WORKDIR /app  # Working directory within the container

#COPY target/*.war /app/ROOT.war  # Copy your WAR file from the target directory (adjust path if needed)

#EXPOSE 8080  # Expose the port for web traffic

#ENTRYPOINT ["java", "-jar", "/app/ROOT.war"]  # Start the application on container startup

