# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker ubuntu

cat <<EOF > docker-compose.yml
services:
  api:
    image: moneydgar/procom:latest
    environment:
      - MONGODB_URI=mongodb://mongodb:27017/rag_db
    ports:
      - "5000:5000"
      - "5001:5001"
    depends_on:
      - mongodb
    runtime: nvidia

  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    command: mongod --setParameter maxTransactionLockRequestTimeoutMillis=5000

  mongo-express:
    image: mongo-express:latest
    environment:
      - ME_CONFIG_MONGODB_SERVER=mongodb
    ports:
      - "8081:8081"
    depends_on:
      - mongodb

volumes:
  mongodb_data:
EOF


sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

docker compose up -d