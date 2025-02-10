# Build stage
FROM amazoncorretto:17-alpine as builder
WORKDIR /build

# Copy the WAR file
COPY target/myapp.war .

# Production stage
FROM amazoncorretto:17-alpine
WORKDIR /usr/local/tomcat

# Add a non-root user
RUN addgroup -S tomcat && \
    adduser -S tomcat -G tomcat

# Install curl and download Tomcat in a single layer
RUN apk add --no-cache curl && \
    curl -fsSL https://downloads.apache.org/tomcat/tomcat-10/v10.1.14/bin/apache-tomcat-10.1.14.tar.gz | \
    tar xzf - --strip-components=1 && \
    rm -rf /usr/local/tomcat/webapps/* && \
    chown -R tomcat:tomcat /usr/local/tomcat

# Copy WAR file from builder stage
COPY --from=builder --chown=tomcat:tomcat /build/myapp.war webapps/ROOT.war

# Set proper permissions
RUN chmod -R 750 /usr/local/tomcat/webapps

# Configure Tomcat to use proper memory settings
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -XX:+UseG1GC"

# Switch to non-root user
USER tomcat

# Expose standard Tomcat port
EXPOSE 8080

CMD ["bin/catalina.sh", "run"]