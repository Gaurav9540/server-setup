#!/bin/bash
set -e

echo "========================================================================================"
echo "SCRIPT STARTED: UBUNTU VPS SERVER UNINSTALLATION"
echo "========================================================================================"
echo "Time: $(date)"
echo

MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"

echo "[1/6] Stopping MySQL service if running..."
if systemctl is-active --quiet mysql; then
    sudo systemctl stop mysql
    echo "✅ MySQL service stopped."
else
    echo "ℹ️ MySQL service already stopped."
fi

echo "[2/6] Uninstalling MySQL server and cleaning data..."
sudo apt purge -y mysql-server mysql-client mysql-common
sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql /var/log/mysql.*
sudo apt autoremove -y
sudo apt autoclean -y
echo "✅ MySQL completely removed."

echo "[3/6] Reverting firewall rule (port 3306)..."
if command -v ufw &> /dev/null
then
    sudo ufw delete allow 3306 || true
    echo "✅ Firewall rule for MySQL removed."
else
    echo "ℹ️ UFW not installed — skipping firewall cleanup."
fi

echo "[4/6] Uninstalling JDK 17..."
sudo apt purge -y openjdk-17-jdk openjdk-17-jre
sudo apt autoremove -y
sudo apt autoclean -y
echo "✅ JDK 17 removed."

echo "[5/6] Cleaning temporary files and apt cache..."
sudo rm -rf /var/cache/apt/archives/*
sudo apt clean
echo "✅ System cleaned."

echo "[6/6] Final verification..."
echo "Remaining Java installations (if any):"
java -version || echo "❌ No Java found"
echo
echo "Remaining MySQL installations (if any):"
mysql --version || echo "❌ No MySQL found"

echo
echo "========================================================================================"
echo "✅ UNINSTALLATION COMPLETED SUCCESSFULLY"
echo "========================================================================================"
echo "Time: $(date)"
echo "All components installed by the previous setup script have been removed."
echo "========================================================================================"
