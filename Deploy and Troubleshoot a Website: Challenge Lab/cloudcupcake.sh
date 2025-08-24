#!/bin/bash
# Automates VM creation, firewall setup, and Apache server deployment

read -p "Enter VM instance name: " VM_NAME
read -p "Enter zone (e.g., us-west1-b): " ZONE

echo "[1/5] Creating VM instance: $VM_NAME in zone: $ZONE..."
gcloud compute instances create $VM_NAME \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --tags=http-server \
    --metadata=startup-script='#!/bin/bash
        apt-get update
        apt-get install -y apache2
        echo "<h1>Hello World!</h1>" > /var/www/html/index.html
        systemctl enable apache2
        systemctl start apache2
    '

echo "[2/5] Creating firewall rule to allow HTTP traffic..."
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --target-tags=http-server \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --quiet || echo "Firewall rule may already exist."

echo "[3/5] Waiting for VM to start..."
sleep 20

EXT_IP=$(gcloud compute instances describe $VM_NAME \
    --zone=$ZONE \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "[4/5] Testing Apache server..."
curl -I http://$EXT_IP

echo "[5/5] Server is up! Visit: http://$EXT_IP"
echo "Expected Output: Hello World!"
