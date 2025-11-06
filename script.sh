#!/bin/bash
set -e

echo -e "${CYAN}"
cat << "EOF"
    ___       __   _______   ___       ________  ________  ________  _____ ______   _______           ________  ________  ___  ___  ________  ________  ___      ___ 
|\  \     |\  \|\  ___ \ |\  \     |\   __  \|\   ____\|\   __  \|\   _ \  _   \|\  ___ \         |\   ____\|\   __  \|\  \|\  \|\   __  \|\   __  \|\  \    /  /|
\ \  \    \ \  \ \   __/|\ \  \    \ \  \|\  \ \  \___|\ \  \|\  \ \  \\\__\ \  \ \   __/|        \ \  \___|\ \  \|\  \ \  \\\  \ \  \|\  \ \  \|\  \ \  \  /  / /
 \ \  \  __\ \  \ \  \_|/_\ \  \    \ \  \\\  \ \  \    \ \  \\\  \ \  \\|__| \  \ \  \_|/__       \ \  \  __\ \   __  \ \  \\\  \ \   _  _\ \   __  \ \  \/  / / 
  \ \  \|\__\_\  \ \  \_|\ \ \  \____\ \  \\\  \ \  \____\ \  \\\  \ \  \    \ \  \ \  \_|\ \       \ \  \|\  \ \  \ \  \ \  \\\  \ \  \\  \\ \  \ \  \ \    / /  
   \ \____________\ \_______\ \_______\ \_______\ \_______\ \_______\ \__\    \ \__\ \_______\       \ \_______\ \__\ \__\ \_______\ \__\\ _\\ \__\ \__\ \__/ /   
    \|____________|\|_______|\|_______|\|_______|\|_______|\|_______|\|__|     \|__|\|_______|        \|_______|\|__|\|__|\|_______|\|__|\|__|\|__|\|__|\|__|/    
EOF
echo -e "${RESET}"  

# ============================== COLORS ==============================
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RED="\e[31m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# ============================== FUNCTIONS ==============================
spinner() {
    local pid=$!
    local spin='|/-\'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${CYAN}${spin:$i:1} ${1}..."
        sleep 0.15
    done
    printf "\r${GREEN}✅ ${1} completed.${RESET}\n"
}

print_header() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "========================================================================================"
    echo " UBUNTU VPS SERVER SETUP SCRIPT"
    echo "========================================================================================"
    echo -e "${RESET}"
    echo "Time: $(date)"
    echo
}

# ============================== SCRIPT START ==============================
print_header

MYSQL_ROOT_PASSWORD="GTasterix@007"
BIND_ADDRESS="0.0.0.0"

echo -e "${YELLOW}[1/8] Updating Packages...${RESET}"
(sudo apt update -y && sudo apt upgrade -y) & spinner "System update"

echo -e "${YELLOW}[2/8] Installing JDK 17...${RESET}"
(sudo apt install -y openjdk-17-jdk) & spinner "Installing JDK 17"

echo -e "${YELLOW}[3/8] Verifying Java Installation...${RESET}"
java --version | grep "openjdk" && echo -e "${GREEN}Java verified.${RESET}"

echo -e "${YELLOW}[4/8] Installing MySQL Server...${RESET}"
(sudo apt install -y mysql-server) & spinner "Installing MySQL Server"

sudo systemctl daemon-reload
sudo systemctl enable mysql
sudo systemctl start mysql

echo -e "${CYAN}⏳ Waiting for MySQL service to fully start...${RESET}"
for i in {1..10}; do
    if sudo systemctl is-active --quiet mysql; then
        echo -e "${GREEN}✅ MySQL service is active.${RESET}"
        break
    fi
    echo -e "${YELLOW}...starting ($i)${RESET}"
    sleep 3
done

echo -e "${YELLOW}[5/8] Resetting MySQL root password...${RESET}"
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo -e "${YELLOW}[6/8] Securing MySQL and enabling remote access...${RESET}"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

# Configure remote access
if sudo grep -q "^bind-address" /etc/mysql/mysql.conf.d/mysqld.cnf; then
    sudo sed -i "s/^bind-address.*/bind-address = ${BIND_ADDRESS}/" /etc/mysql/mysql.conf.d/mysqld.cnf
else
    echo "bind-address = ${BIND_ADDRESS}" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf
fi

sudo systemctl restart mysql

if command -v ufw &> /dev/null; then
    sudo ufw allow 3306 || true
fi

echo -e "${YELLOW}[7/8] Cleaning up unused packages...${RESET}"
(sudo apt autoremove -y) & spinner "Cleanup"

echo -e "${YELLOW}[8/8] Verifying MySQL root login...${RESET}"
if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 'Login successful ✅' AS Status;" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ MySQL root login verified successfully.${RESET}"
else
    echo -e "${RED}❌ MySQL login test failed — please check manually.${RESET}"
fi

# ============================== COMPLETION ==============================
echo
echo -e "${BOLD}${BLUE}"
echo "========================================================================================"
echo " ✅ SERVER SETUP COMPLETED SUCCESSFULLY"
echo "========================================================================================"
echo -e "${RESET}"
echo "Time: $(date)"
echo
echo -e "${CYAN}MySQL root password:${RESET} ${BOLD}${MYSQL_ROOT_PASSWORD}${RESET}"
echo -e "${CYAN}Login using:${RESET} ${BOLD}sudo mysql -u root -p${RESET}"
echo -e "${BLUE}========================================================================================${RESET}"
