#!/bin/bash
set -e

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
    echo " UBUNTU VPS SERVER UNINSTALLATION SCRIPT"
    echo "========================================================================================"
    echo -e "${RESET}"
    echo "Time: $(date)"
    echo
}

confirm_execution() {
    echo -e "${YELLOW}========================================================================================${RESET}"
    echo -e "${RED}${BOLD}⚠️  WARNING:${RESET} This script will completely uninstall MySQL, JDK 17, and related data."
    echo -e "${YELLOW}========================================================================================${RESET}"
    echo
    read -p "Are you sure you want to continue? (yes/no): " CONFIRM

    if [[ "$CONFIRM" != "yes" ]]; then
        echo -e "${RED}❌ Operation cancelled by user.${RESET}"
        exit 1
    fi

    echo -e "${GREEN}✅ Confirmation received. Continuing...${RESET}"
    echo
    sleep 1
}

# ============================== SCRIPT START ==============================
print_header
confirm_execution   # <--- Added here

MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"

echo -e "${YELLOW}[1/6] Stopping MySQL service if running...${RESET}"
if systemctl is-active --quiet mysql; then
    (sudo systemctl stop mysql) & spinner "Stopping MySQL service"
else
    echo -e "${CYAN}ℹ️ MySQL service already stopped.${RESET}"
fi

echo -e "${YELLOW}[2/6] Uninstalling MySQL server and cleaning data...${RESET}"
(
    sudo apt purge -y mysql-server mysql-client mysql-common
    sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql /var/log/mysql.*
    sudo apt autoremove -y
    sudo apt autoclean -y
) & spinner "Removing MySQL components"

echo -e "${YELLOW}[3/6] Reverting firewall rule (port 3306)...${RESET}"
if command -v ufw &> /dev/null; then
    (sudo ufw delete allow 3306 || true) & spinner "Removing firewall rule for MySQL"
else
    echo -e "${CYAN}ℹ️ UFW not installed — skipping firewall cleanup.${RESET}"
fi

echo -e "${YELLOW}[4/6] Uninstalling JDK 17...${RESET}"
(
    sudo apt purge -y openjdk-17-jdk openjdk-17-jre
    sudo apt autoremove -y
    sudo apt autoclean -y
) & spinner "Removing JDK 17"

echo -e "${YELLOW}[5/6] Cleaning temporary files and apt cache...${RESET}"
(
    sudo rm -rf /var/cache/apt/archives/*
    sudo apt clean
) & spinner "Cleaning system cache"

echo -e "${YELLOW}[6/6] Final verification...${RESET}"
echo
echo -e "${CYAN}Remaining Java installations (if any):${RESET}"
java -version 2>/dev/null || echo -e "${RED}❌ No Java found${RESET}"

echo
echo -e "${CYAN}Remaining MySQL installations (if any):${RESET}"
mysql --version 2>/dev/null || echo -e "${RED}❌ No MySQL found${RESET}"

# ============================== COMPLETION ==============================
echo
echo -e "${BOLD}${BLUE}"
echo "========================================================================================"
echo " ✅ UNINSTALLATION COMPLETED SUCCESSFULLY"
echo "========================================================================================"
echo -e "${RESET}"
echo "Time: $(date)"
echo
echo -e "${CYAN}All components installed by the setup script have been completely removed.${RESET}"
echo -e "${BLUE}========================================================================================${RESET}"
