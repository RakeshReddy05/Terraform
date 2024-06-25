#!/bin/bash


apt update


apt install -y apache2

# Get the instance ID from the instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

apt install -y awscli

# Create a simple HTML file with the instance ID
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Your Web Server1</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        h1 { color: #4CAF50; }
    </style>
</head>
<body>
    <h1>Welcome to Your AWS Ubuntu Micro Instance!</h1>
    <p>This is a simple web page served by NGINX on your AWS Ubuntu micro instance.</p>
    <h2>Instance ID: <span style="color:green">$INSTANCE_ID</span></h2>
</body>
</html>
EOF

systemctl start apache2
systemctl enable apache2
