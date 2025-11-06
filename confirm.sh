#!/bin/bash
set -e

echo "========================================================================================"
echo "⚠️  WARNING: You are about to run $(basename "$0")"
echo "========================================================================================"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "❌ Operation cancelled by user."
    exit 1
fi

echo "✅ Confirmation received. Continuing..."
