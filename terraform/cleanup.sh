#!/bin/bash

# Magic Movie Machine - Cleanup Script
# This script safely removes all infrastructure

set -e

echo "╔═════════════════════════════════════════════════════════════╗"
echo "║      Magic Movie Machine - Infrastructure Cleanup           ║"
echo "╚═════════════════════════════════════════════════════════════╝"

echo ""
echo "⚠️  WARNING: This will delete all AWS resources created by Terraform!"
echo ""

read -p "Are you sure you want to proceed? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

cd terraform/

echo ""
echo "🧹 Removing AWS resources..."
terraform destroy

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "ℹ️  Note: You may need to manually delete:"
echo "   - S3 bucket objects"
echo "   - Personalize resources"
echo "   - Any CloudFormation stacks"
