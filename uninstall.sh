#!/bin/bash
set -e

echo "========================================================================================"
echo "UNINSTALL SCRIPT STARTED: REMOVING UBUNTU VPS SERVER SETUP"
echo "========================================================================================"
echo "Time: $(date)"
echo

echo "[1/7] Stopping MySQL Service..."
sudo systemctl stop mysql || true
sudo systemctl disable mysql || true

echo "[2/7] Removing MySQL Server and Config Files..."
sudo apt remove --purge -y mysql-server mysql-client mysql-common
sudo apt autoremove -y
sudo apt autoclean -y

echo "[3/7] Deleting MySQL Data Directory..."
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/mysql
sudo rm -rf /run/mysqld

echo "[4/7] Removing JDK 17..."
sudo apt remove --purge -y openjdk-17-jdk openjdk-17-jre
sudo apt autoremove -y

echo "[5/7] Removing Firewall Allow Rule for MySQL..."
if command -v ufw &> /dev/null
then
    sudo ufw delete allow 3306 || true
fi

echo "[6/7] Cleaning Up Unused Packages..."
sudo apt autoremove -y
sudo apt clean

echo "[7/7] Verification..."
echo "Java version:"
java --version || echo "Java removed"
echo
echo "MySQL status:"
systemctl status mysql || echo "MySQL removed"

echo
echo "========================================================================================"
echo "✅ UNINSTALLATION COMPLETED SUCCESSFULLY"
echo "========================================================================================"
echo "Time: $(date)"
