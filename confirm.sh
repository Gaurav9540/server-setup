#!/bin/bash
set -e

# Colors and styles
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"
CYAN="\e[36m"; BOLD="\e[1m"; RESET="\e[0m"

# Wave text animation
wave_text() {
    local text="$1"
    for ((i=0; i<${#text}; i++)); do
        printf "\e[38;5;$((31 + (i % 6)))m${text:$i:1}${RESET}"
        sleep 0.05
    done
    echo
}

clear
echo
wave_text "========================================================================================"
wave_text "⚠️   WARNING: You are about to run $(basename "$0")"
wave_text "========================================================================================"
echo
