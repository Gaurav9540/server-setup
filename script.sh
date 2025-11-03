#!/bin/bash
set -e

echo "========================================================================================"

echo "SCRIPT STARTED: UBUNTU VPS SERVER SETUP"

echo "========================================================================================"

echo "Time: $(date)"
echo

# Variables
MYSQL_ROOT_PASSWORD="GTasterix@007"
BIND_ADDRESS="0.0.0.0"

echo "[1/8] Updating Packages..."
sudo apt update -y
sudo apt upgrade -y

echo "[2/8] Installing JDK 17..."
sudo apt install -y openjdk-17-jdk

echo "[3/8] Verifying Java Installation..."
java --version

echo "[4/8] Installing MySQL Server..."
sudo apt install -y mysql-server

sudo systemctl daemon-reload
sudo systemctl enable mysql
sudo systemctl start mysql

echo "Waiting for MySQL service to fully start..."
for i in {1..10}; do
    if sudo systemctl is-active --quiet mysql; then
        echo "✅ MySQL service is active."
        break
    fi
    echo "⏳ Waiting... ($i)"
    sleep 3
done

echo "[5/8] Resetting MySQL root password (secure method)..."
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo "[6/8] Securing MySQL and enabling remote access..."
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

# Allow remote access
if sudo grep -q "^bind-address" /etc/mysql/mysql.conf.d/mysqld.cnf; then
    sudo sed -i "s/^bind-address.*/bind-address = ${BIND_ADDRESS}/" /etc/mysql/mysql.conf.d/mysqld.cnf
else
    echo "bind-address = ${BIND_ADDRESS}" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf
fi

sudo systemctl restart mysql

# Allow MySQL in firewall if UFW exists
if command -v ufw &> /dev/null
then
    sudo ufw allow 3306 || true
fi

echo "[7/8] Cleaning up unused packages..."
sudo apt autoremove -y

echo "[8/8] Verifying MySQL root login..."
if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 'Login successful ✅' AS Status;" >/dev/null 2>&1; then
    echo "✅ MySQL root login verified successfully."
else
    echo "❌ MySQL login test failed — please check manually."
fi

echo

echo "========================================================================================"

echo "✅ SCRIPT COMPLETED: SERVER SETUP SUCCESSFUL"

echo "========================================================================================"

echo "Time: $(date)"

echo "MySQL root password: ${MYSQL_ROOT_PASSWORD}"

echo "Login using: sudo mysql -u root -p"

echo "========================================================================================"
