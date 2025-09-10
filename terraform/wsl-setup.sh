#!/bin/bash
# Complete WSL Ubuntu setup script for GoGreen Insurance Terraform

echo "🚀 GoGreen Insurance - WSL Ubuntu Setup"
echo "========================================"

# Check if running in WSL
if ! grep -q Microsoft /proc/version; then
    echo "⚠️  Warning: This doesn't appear to be WSL. Some commands may not work."
fi

# Make scripts executable
echo "📝 Making scripts executable..."
chmod +x *.sh

# Install AWS CLI if not present
echo "🔧 Checking AWS CLI installation..."
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    echo "✅ AWS CLI installed"
else
    echo "✅ AWS CLI already installed"
fi

# Install Terraform if not present
echo "🔧 Checking Terraform installation..."
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform
    echo "✅ Terraform installed"
else
    echo "✅ Terraform already installed"
fi

# Setup AWS credentials
echo "🔐 Setting up AWS credentials..."
./setup-aws-config.sh

# Test credentials
echo "🧪 Testing credentials..."
./validate-credentials.sh

# If credentials fail, try reset
if [ $? -ne 0 ]; then
    echo "🔄 Credentials failed, trying reset..."
    ./reset-credentials.sh
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. If credentials are valid, run: terraform init"
echo "2. Then run: terraform plan"
echo "3. Finally run: terraform apply"
echo ""
echo "If you get credential errors, check your AWS credentials in aws-credentials.env"
