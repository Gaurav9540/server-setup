#!/bin/bash
set -e

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; CYAN="\e[36m"; RESET="\e[0m"; BOLD="\e[1m"

wave_text() {
    local text="$1"
    for ((i=0; i<${#text}; i++)); do
        printf "\e[38;5;$((31 + (i % 6)))m${text:$i:1}${RESET}"
        sleep 0.03
    done
    echo
}

type_text() {
    local text="$1"
    for ((i=0; i<${#text}; i++)); do
        printf "${text:$i:1}"
        sleep 0.02
    done
    echo
}

spinner() {
    local pid=$!
    local spin='🌕🌖🌗🌘🌑🌒🌓🌔'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 8 ))
        printf "\r${CYAN}Verifying ${spin:$i:1}${RESET}"
        sleep 0.1
    done
    printf "\r"
}

clear
wave_text "========================================================================================"
wave_text "⚠️  WARNING: You are about to run $(basename "$0")"
wave_text "========================================================================================"
echo
type_text "This script may make system-level changes."
echo

read -p "👉 Type 'yes' to confirm and continue: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    type_text "${RED}❌ Operation cancelled.${RESET}"
    exit 1
fi

# Simulate verification
(sleep 2) & spinner
type_text "${GREEN}✅ Confirmation accepted. Proceeding...${RESET}"
sleep 0.5
clear
wave_text "🚀 Starting execution..."

                                                                                                                                                                  
                                                                                                                                                                  
                                                                                                                                                     
