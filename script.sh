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

echo "[1/9] Updating Packages..."
sudo apt update -y
sudo apt upgrade -y

echo "[2/9] Installing JDK 17..."
sudo apt install -y openjdk-17-jdk

echo "[3/9] Verifying Java Installation..."
java --version

echo "[4/9] Installing MySQL Server..."
sudo apt install -y mysql-server

echo "[5/9] Ensuring MySQL socket directory exists..."
sudo mkdir -p /run/mysqld
sudo chown mysql:mysql /run/mysqld

echo "[6/9] Starting MySQL in skip-grant-tables mode to reset root password..."
sudo systemctl stop mysql || true
sudo mysqld --skip-grant-tables --skip-networking &
sleep 8

echo "[7/9] Resetting MySQL root password..."
mysql -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo "[8/9] Restarting MySQL normally..."
sudo killall mysqld || true
sleep 5
sudo systemctl start mysql
sudo systemctl enable mysql

echo "[9/9] Securing MySQL and enabling remote access..."
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
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

echo "Cleaning up unused packages..."
sudo apt autoremove -y

echo
echo "========================================================================================"
echo "✅ SCRIPT COMPLETED: SERVER SETUP SUCCESSFUL"
echo "========================================================================================"
echo "Time: $(date)"
echo "MySQL root password: ${MYSQL_ROOT_PASSWORD}"
echo "Login using: sudo mysql -u root -p"
echo "========================================================================================"
