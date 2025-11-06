#!/bin/bash
set -e

# ========== COLORS ==========
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# ========== FUNCTIONS ==========

# Typing animation
type_text() {
    local text="$1"
    local delay="${2:-0.03}"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

# Spinner animation
spinner() {
    local pid=$!
    local spin='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r${CYAN}Verifying${spin:$i:1}${RESET}"
        sleep 0.1
    done
    printf "\r"
}

# ========== MAIN ==========

clear
echo -e "${YELLOW}========================================================================================${RESET}"
type_text "⚠️  WARNING: You are about to run $(basename "$0")"
echo -e "${YELLOW}========================================================================================${RESET}"
type_text "This action may modify your system or services."
echo

read -p "👉 Are you sure you want to continue? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    type_text "${RED}❌ Operation cancelled by user.${RESET}"
    exit 1
fi

# Simulate verification with spinner
(sleep 2) & spinner
type_text "${GREEN}✅ Confirmation received. Continuing...${RESET}"
echo
sleep 0.5
