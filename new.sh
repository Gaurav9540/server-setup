#!/bin/bash
set -e

# ========================== COLORS ==========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ========================== SPINNER FUNCTION ==========================
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "     \b\b\b\b\b"
}

# ========================== HEADER ==========================
clear
echo -e "${BLUE}${BOLD}========================================================================================${NC}"
echo -e "${GREEN}${BOLD}SCRIPT STARTED: UBUNTU VPS SERVER SETUP${NC}"
echo -e "${BLUE}${BOLD}========================================================================================${NC}"
echo -e "${YELLOW}Time: $(date)${NC}\n"

# ========================== VARIABLES ==========================
MYSQL_ROOT_PASSWORD="GTasterix@007"
BIND_ADDRESS="0.0.0.0"

# ========================== TASKS ==========================
echo -e "${YELLOW}[1/8] Updating Packages...${NC}"
(sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1) & spinner
echo -e "${GREEN}✅ Packages Updated.${NC}\n"

echo -e "${YELLOW}[2/8] Installing JDK 17...${NC}"
(sudo apt install -y openjdk-17-jdk >/dev/null 2>&1) & spinner
echo -e "${GREEN}✅ JDK 17 Installed.${NC}\n"

echo -e "${YELLOW}[3/8] Verifying Java Installation...${NC}"
java --version
echo

echo -e "${YELLOW}[4/8] Installing MySQL Server...${NC}"
(sudo apt install -y mysql-server >/dev/null 2>&1) & spinner
echo -e "${GREEN}✅ MySQL Installed.${NC}"

sudo systemctl daemon-reload
sudo systemctl enable mysql
sudo systemctl start mysql

echo "Waiting for MySQL service to fully start..."
for i in {1..10}; do
    if sudo systemctl is-active --quiet mysql; then
        echo -e "${GREEN}✅ MySQL service is active.${NC}"
        break
    fi
    echo -e "${YELLOW}⏳ Waiting... ($i)${NC}"
    sleep 3
done

echo -e "${YELLOW}[5/8] Resetting MySQL root password (secure method)...${NC}"
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo -e "${YELLOW}[6/8] Securing MySQL and enabling remote access...${NC}"
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
if command -v ufw &> /dev/null; then
    sudo ufw allow 3306 || true
fi

echo -e "${YELLOW}[7/8] Cleaning up unused packages...${NC}"
(sudo apt autoremove -y >/dev/null 2>&1) & spinner
echo -e "${GREEN}✅ Cleanup Completed.${NC}\n"

echo -e "${YELLOW}[8/8] Verifying MySQL root login...${NC}"
if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 'Login successful ✅' AS Status;" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ MySQL root login verified successfully.${NC}"
else
    echo -e "${RED}❌ MySQL login test failed — please check manually.${NC}"
fi

# ========================== FOOTER ==========================
echo
echo -e "${BLUE}${BOLD}========================================================================================${NC}"
echo -e "${GREEN}${BOLD}✅ SCRIPT COMPLETED: SERVER SETUP SUCCESSFUL${NC}"
echo -e "${BLUE}${BOLD}========================================================================================${NC}"
echo -e "${YELLOW}Time: $(date)${NC}"
echo -e "${YELLOW}MySQL root password:${NC} ${BOLD}${MYSQL_ROOT_PASSWORD}${NC}"
echo -e "${YELLOW}Login using:${NC} ${BOLD}sudo mysql -u root -p${NC}"
echo -e "${BLUE}${BOLD}========================================================================================${NC}\n"
