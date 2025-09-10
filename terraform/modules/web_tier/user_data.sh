#!/bin/bash
# User data script for GoGreen Insurance web tier instances

# Update system
yum update -y

# Install required packages
yum install -y httpd php php-mysqlnd php-xml php-gd php-mbstring

# Install Apache Tomcat
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.XX/bin/apache-tomcat-8.5.XX.tar.gz
tar -xzf apache-tomcat-8.5.XX.tar.gz
mv apache-tomcat-8.5.XX /opt/tomcat

# Configure Apache
systemctl start httpd
systemctl enable httpd

# Configure Tomcat
systemctl start tomcat
systemctl enable tomcat

# Create web application directory
mkdir -p /var/www/html/gogreen
chown -R apache:apache /var/www/html/gogreen

# Create a simple health check page
cat > /var/www/html/health.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>GoGreen Insurance - Health Check</title>
</head>
<body>
    <h1>GoGreen Insurance Web Tier</h1>
    <p>Status: Healthy</p>
    <p>Tier: ${tier}</p>
    <p>Timestamp: $(date)</p>
</body>
</html>
EOF

# Create a simple index page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>GoGreen Insurance</title>
</head>
<body>
    <h1>Welcome to GoGreen Insurance</h1>
    <p>Your trusted insurance partner</p>
    <p><a href="/health.html">Health Check</a></p>
</body>
</html>
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure Apache to serve the application
cat > /etc/httpd/conf.d/gogreen.conf << 'EOF'
<VirtualHost *:80>
    ServerName gogreen-insurance.local
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog /var/log/httpd/gogreen_error.log
    CustomLog /var/log/httpd/gogreen_access.log combined
</VirtualHost>
EOF

# Restart Apache
systemctl restart httpd

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "GoGreen/WebTier",
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
echo "GoGreen Insurance web tier setup completed at $(date)" >> /var/log/gogreen-setup.log
