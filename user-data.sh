#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
set -xe

# Update system and install dependencies
apt-get update -y
apt-get upgrade -y
apt-get install -y docker.io git curl
systemctl enable docker
systemctl start docker

# Install Docker Compose v2
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Ensure docker is up
sleep 5
docker ps

# Clone repo (retry once if failed)
cd /home/ubuntu || cd /root
git clone https://github.com/GfavourBraimah/Web_Monitoring || {
  echo "Clone failed, retrying..."
  sleep 10
  git clone https://github.com/GfavourBraimah/Web_Monitoring
}

cd Web_Monitoring
# Start services
docker-compose up -d

# Health check script
cat > /usr/local/bin/check-status << 'EOF'
#!/bin/bash
echo "=== Monitoring Stack Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Access URLs:"
echo "Grafana: http://localhost:3000 (admin/admin)"
echo "Prometheus: http://localhost:9090"
echo "Web App: http://localhost:5000"
EOF

chmod +x /usr/local/bin/check-status

echo "Setup complete! Run 'check-status' to verify the stack is running."
