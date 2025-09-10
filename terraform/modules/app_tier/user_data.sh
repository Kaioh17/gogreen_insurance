#!/bin/bash
# User data script for GoGreen Insurance application tier instances

# Update system
yum update -y

# Install required packages
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
yum install -y mysql-connector-java

# Install Apache Tomcat
wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.XX/bin/apache-tomcat-8.5.XX.tar.gz
tar -xzf apache-tomcat-8.5.XX.tar.gz
mv apache-tomcat-8.5.XX /opt/tomcat

# Set environment variables
echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk' >> /etc/environment
echo 'export CATALINA_HOME=/opt/tomcat' >> /etc/environment
echo 'export PATH=$PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin' >> /etc/environment

# Create tomcat user
useradd -r -s /bin/false tomcat
chown -R tomcat:tomcat /opt/tomcat

# Create systemd service for Tomcat
cat > /etc/systemd/system/tomcat.service << 'EOF'
[Unit]
Description=Apache Tomcat 8
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_OPTS=-Xms512M -Xmx2048M -server -XX:+UseParallelGC
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Configure Tomcat
cat > /opt/tomcat/conf/server.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />

  <GlobalNamingResources>
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>

  <Service name="Catalina">
    <Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
               maxThreads="150" SSLEnabled="true">
        <SSLHostConfig>
            <Certificate certificateKeyFile="conf/localhost-rsa-key.pem"
                         certificateFile="conf/localhost-rsa-cert.pem"
                         type="RSA" />
        </SSLHostConfig>
    </Connector>

    <Engine name="Catalina" defaultHost="localhost">
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>

      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />
      </Host>
    </Engine>
  </Service>
</Server>
EOF

# Create application directory
mkdir -p /opt/tomcat/webapps/gogreen
chown -R tomcat:tomcat /opt/tomcat/webapps

# Create a simple health check servlet
cat > /opt/tomcat/webapps/gogreen/health.jsp << 'EOF'
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>GoGreen Insurance - Application Tier Health Check</title>
</head>
<body>
    <h1>GoGreen Insurance Application Tier</h1>
    <p>Status: Healthy</p>
    <p>Tier: ${tier}</p>
    <p>Timestamp: <%= new java.util.Date() %></p>
    <p>JVM Version: <%= System.getProperty("java.version") %></p>
    <p>Available Memory: <%= Runtime.getRuntime().freeMemory() / 1024 / 1024 %> MB</p>
    <p>Total Memory: <%= Runtime.getRuntime().totalMemory() / 1024 / 1024 %> MB</p>
</body>
</html>
EOF

# Create a simple application page
cat > /opt/tomcat/webapps/gogreen/index.jsp << 'EOF'
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>GoGreen Insurance - Application</title>
</head>
<body>
    <h1>Welcome to GoGreen Insurance Application</h1>
    <p>Your trusted insurance partner</p>
    <p><a href="health.jsp">Health Check</a></p>
    <p>Application Tier is running on: <%= request.getServerName() %></p>
</body>
</html>
EOF

# Set proper permissions
chown -R tomcat:tomcat /opt/tomcat

# Start and enable Tomcat
systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "GoGreen/AppTier",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Log completion
echo "GoGreen Insurance application tier setup completed at $(date)" >> /var/log/gogreen-setup.log
