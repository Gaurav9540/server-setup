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
sudo apt install openjdk-17-jdk -y

echo "[3/8] Verifying Java Installation..."
java --version

echo "[4/8] Installing MySQL Server..."
sudo apt install mysql-server -y

echo "[5/8] Verifying MySQL Server Installation..."
sudo systemctl status mysql --no-pager || true

echo "[6/8] Configuring MySQL root user and basic security..."

# Secure MySQL setup
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_ROOT_PASSWORD}';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Remove anonymous users and test DB
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS test;"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

echo "[7/8] Configuring remote access in MySQL..."
# Fix config path for Ubuntu MySQL 8
sudo sed -i "s/^bind-address.*/bind-address = ${BIND_ADDRESS}/" /etc/mysql/mysql.conf.d/mysqld.cnf

echo "[8/8] Restarting MySQL..."
sudo systemctl restart mysql
sudo systemctl enable mysql

echo "[9/8] Allowing MySQL in firewall if UFW exists..."
if command -v ufw &> /dev/null
then
    sudo ufw allow 3306
fi

echo "Cleaning up unused packages..."
sudo apt autoremove -y

echo
echo "========================================================================================"
echo "✅ SCRIPT COMPLETED: SETUP SUCCESSFUL"
echo "========================================================================================"
echo "Time: $(date)"
echo "MySQL root password: ${MYSQL_ROOT_PASSWORD}"
echo "Login using: sudo mysql -u root -p"
echo "========================================================================================"
