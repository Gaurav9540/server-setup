#!/bin/bash
set -e

echo "========================================================================================"
echo "SCRIPT STARTED: UBUNTU VPS SERVER SETUP"
echo "========================================================================================"
echo "Time: $(date)"
echo

MYSQL_ROOT_PASSWORD="GTasterix@007"
BIND_ADDRESS="0.0.0.0"

echo "[1/8] Updating Packages...."
sudo apt update -y
sudo apt upgrade -y

echo "[2/8] Installing JDK 17..."
sudo apt install openjdk-17-jdk -y

echo "[3/8] Verifying Java Installation..."
java --version

echo "[4/8] Installing MYSQL Server..."
sudo apt install mysql-server -y 

echo "[5/8] Verifying MYSQL Server Installation..."
echo "[6/8] Configuring MYSQL root user and basic security..."

# Secure MySQL setup
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_password BY '${MYSQL_ROOT_PASSWORD}';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Remove anonumous users and test DB
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS test;"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

echo "[7/8] Configuring remote access in MySQL..."
sudo sed -i "s/^bind-address.*/bind-address = ${BIND_ADDRESS}/" /etc/mysql/mysql.conf.d/mysql.cnf

echo "[8/8] Restarting MySQL..."
sudo systemctl restart mysql
sudo systemctl enable mysql

echo "[9/8] Allowing MySQL in firewall if UFW exists..."
if command -v ufw &> /dev/null
then 
   sudo ufw allow 3306
fi

echo "Cleaning Up..."
sudo apt autoremove -y 

echo "Setup Completed...!"

echo "MySQL root password: ${MYSQL_ROOT_PASSWORD}"

echo "========================================================================================"
echo "SCRIPT COMPLETED: SETUP SUCCESSFUL"
echo "========================================================================================"