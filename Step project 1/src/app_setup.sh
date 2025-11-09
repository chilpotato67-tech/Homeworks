#!/usr/bin/env bash
set -e

echo "=== Installing Java, Git, Maven ==="
sudo apt-get update -y -q
sudo apt-get install -y -q openjdk-17-jdk git maven netcat

APP_USER="appuser"
REPO_DIR="/home/${APP_USER}/spring-petclinic"
PROJECT_DIR="${REPO_DIR}/devops_soft-main/forStep1/PetClinic"
APP_DIR="/home/${APP_USER}/app"

# --- Create user if not exists ---
sudo id -u ${APP_USER} &>/dev/null || sudo useradd -m -s /bin/bash ${APP_USER}

# --- Clone or update repo ---
echo "=== Cloning or updating project ==="
if [ ! -d "$REPO_DIR" ]; then
  echo "[INFO] Cloning PetClinic repository..."
  sudo -u ${APP_USER} git clone https://gitlab.com/chilpotato67/spring-petclinic.git ${REPO_DIR}
else
  echo "[INFO] Repository exists — pulling latest changes..."
  cd ${REPO_DIR}
  sudo -u ${APP_USER} git pull -q
fi

# --- Navigate to actual project directory ---
echo "=== Navigating to project directory ==="
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[ERROR] Project directory not found: $PROJECT_DIR"
  exit 1
fi
cd ${PROJECT_DIR}

# --- Wait for DB ---
echo "[INFO] Waiting for MySQL (${DB_HOST}:${DB_PORT}) to become available..."
until nc -z ${DB_HOST} ${DB_PORT}; do
  echo "  → waiting..."
  sleep 3
done
echo "[OK] MySQL is up!"

# --- Ensure Maven Wrapper permissions ---
if [ -f "./mvnw" ]; then
  sudo chmod +x ./mvnw
  echo "[INFO] mvnw permissions fixed"
else
  echo "[WARN] mvnw not found — using global mvn"
fi

# --- Build project ---
echo "=== Building project ==="
if [ -f "./mvnw" ]; then
  sudo -u ${APP_USER} ./mvnw clean package -DskipTests
else
  sudo -u ${APP_USER} mvn clean package -DskipTests
fi

# --- Copy JAR to app folder ---
echo "=== Copying built JAR ==="
JAR_FILE=$(find ${PROJECT_DIR}/target -name "*.jar" | head -n 1)
if [ -z "$JAR_FILE" ]; then
  echo "[ERROR] No JAR file found!"
  exit 1
fi

sudo -u ${APP_USER} mkdir -p ${APP_DIR}
sudo cp ${JAR_FILE} ${APP_DIR}/petclinic.jar
sudo chown ${APP_USER}:${APP_USER} ${APP_DIR}/petclinic.jar

# --- Store DB config globally ---
echo "=== Writing environment variables ==="
cat <<EOF | sudo tee /etc/environment > /dev/null
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
EOF

# --- Create systemd service ---
echo "=== Creating systemd service ==="
SERVICE_FILE="/etc/systemd/system/petclinic.service"

cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=Spring PetClinic Application
After=network.target

[Service]
User=${APP_USER}
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/java -jar ${APP_DIR}/petclinic.jar
Restart=always
RestartSec=10
EnvironmentFile=/etc/environment
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF

# --- Reload systemd & start service ---
sudo systemctl daemon-reload
sudo systemctl enable petclinic.service
sudo systemctl restart petclinic.service

echo "✅ PetClinic systemd service is running!"
echo "🌍 Access: http://192.168.56.11:8080/"
echo "📝 Logs:   journalctl -u petclinic -f"
