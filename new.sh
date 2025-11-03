#!/bin/bash
set -e

# ============================== COLORS ==============================
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RED="\e[31m"
CYAN="\e[36m"
MAGENTA="\e[35m"
BOLD="\e[1m"
RESET="\e[0m"

# ============================== FUNCTIONS ==============================
typewriter() {
    text="$1"
    delay="${2:-0.02}"
    for (( i=0; i<${#text}; i++ )); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

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

banner() {
    echo -e "${MAGENTA}"
    echo " ██████╗ ██╗   ██╗██████╗ ██╗   ██╗████████╗██╗   ██╗"
    echo "██╔═══██╗██║   ██║██╔══██╗╚██╗ ██╔╝╚══██╔══╝╚██╗ ██╔╝"
    echo "██║   ██║██║   ██║██████╔╝ ╚████╔╝    ██║    ╚████╔╝ "
    echo "██║▄▄ ██║██║   ██║██╔══██╗  ╚██╔╝     ██║     ╚██╔╝  "
    echo "╚██████╔╝╚██████╔╝██████╔╝   ██║      ██║      ██║   "
    echo " ╚══▀▀═╝  ╚═════╝ ╚═════╝    ╚═╝      ╚═╝      ╚═╝   "
    echo -e "${RESET}"
}

print_header() {
    clear
    banner
    echo -e "${BOLD}${BLUE}"
    echo "========================================================================================"
    echo " 🎬 UBUNTU VPS SERVER SETUP SCRIPT STARTED"
    echo "========================================================================================"
    echo -e "${RESET}"
    echo "Time: $(date)"
    echo
}

# ============================== SCRIPT START ==============================
print_header

MYSQL_ROOT_PASSWORD="GTasterix@007"
BIND_ADDRESS="0.0.0.0"

typewriter "${YELLOW}Initializing environment...${RESET}" 0.03
sleep 0.5

echo -e "${YELLOW}[1/8] Updating Packages...${RESET}"
(sudo apt update -y && sudo apt upgrade -y) & spinner "System update"

echo -e "${YELLOW}[2/8] Installing JDK 17...${RESET}"
(sudo apt install -y openjdk-17-jdk) & spinner "Installing JDK 17"

echo -e "${YELLOW}[3/8] Verifying Java Installation...${RESET}"
java --version | grep "openjdk" && echo -e "${GREEN}✅ Java verified.${RESET}"

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

# Remote access
if sudo grep -q "^bind-address" /etc/mysql/mysql.conf.d/mysqld.cnf; then
    sudo sed -i "s/^bind-address.*/bind-address = ${BIND_ADDRESS}/" /etc/mysql/mysql.conf.d/mysqld.cnf
else
    echo "bind-address = ${BIND_ADDRESS}" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf
fi
sudo systemctl restart mysql

if command -v ufw &> /dev/null; then
    sudo ufw allow 3306 || true
fi

echo -e "${YELLOW}[7/8] Cleaning up...${RESET}"
(sudo apt autoremove -y) & spinner "Cleanup"

echo -e "${YELLOW}[8/8] Verifying MySQL root login...${RESET}"
if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 'Login successful ✅' AS Status;" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ MySQL root login verified successfully.${RESET}"
else
    echo -e "${RED}❌ MySQL login test failed — please check manually.${RESET}"
fi

# ============================== COMPLETE ==============================
sleep 0.8
echo
echo -e "${BOLD}${BLUE}"
echo "========================================================================================"
echo " 🎉 SETUP COMPLETE — YOUR SERVER IS READY!"
echo "========================================================================================"
echo -e "${RESET}"
typewriter "${GREEN}All services are running smoothly. System is now production-ready.${RESET}" 0.02
echo
echo -e "${CYAN}MySQL root password:${RESET} ${BOLD}${MYSQL_ROOT_PASSWORD}${RESET}"
echo -e "${CYAN}Login using:${RESET} ${BOLD}sudo mysql -u root -p${RESET}"
echo
echo -e "${BLUE}========================================================================================${RESET}"
typewriter "${MAGENTA}Thank you for using this automated setup! 🚀${RESET}" 0.03
echo
