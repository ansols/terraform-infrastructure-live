#!/bin/bash

# Check that we are running in an environment containing the needed files.
if [ ! -f azurestate.tf ]; then
  echo "Need to be runned in scripts/azure"
  exit 1
fi

# Check that we have the needed tools installed
#az --version >/dev/null 2>&1 || (echo "az is required, please install, https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest " ; exit 1)
# Check if Terraform is installed
#terraform --version >/dev/null 2>&1 || (echo "terraform is required, please install, https://www.terraform.io/intro/getting-started/install.html" ; exit 1)
# Check if Terraform is installed
#terragrunt --version >/dev/null 2>&1 || (echo "terragrunt is required, please install, https://github.com/gruntwork-io/terragrunt/releases" ; exit 1)

# Check if we already have created sourceme
if [ ! -f ../../azure/sourceme.sh ]; then
  # Based on: https://docs.microsoft.com/sv-se/azure/virtual-machines/linux/terraform-install-configure?toc=https%3A%2F%2Fdocs.microsoft.com%2Fsv-se%2Fazure%2Fterraform%2Ftoc.json&bc=https%3A%2F%2Fdocs.microsoft.com%2Fsv-se%2Fazure%2Fbread%2Ftoc.json
  echo "Createing a service principal to use for terragrunt"
  az login
  # Choose subscription id
  az account list --query "[].{name:name, subscriptionId:id, tenantId:tenantId}" 
  read -ep "Paste in the subscription ID we should use: " subscription
  echo "Subscription $subscription"
  az account set --subscription="${subscription}"
  az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${subscription}" -n"http://terragrunt" -o json > sp.json
  echo "# Autogenerated file from bootstrap " > tmpsourcemesh
  echo "export ARM_SUBSCRIPTION_ID=$subscription" >> tmpsourcemesh
  #echo "export ARM_CLIENT_ID" >> tmpsourcemesh
  egrep -o '"appId": .*?[^\\]"' sp.json | sed 's/"appId": /export ARM_CLIENT_ID=/' >> tmpsourcemesh
  egrep -o '"password": .*?[^\\]"' sp.json | sed 's/"password": /export ARM_CLIENT_SECRET=/' >> tmpsourcemesh
  egrep -o '"tenant": .*?[^\\]"' sp.json | sed 's/"tenant": /export ARM_TENANT_ID=/' >> tmpsourcemesh
  echo "export ARM_ENVIRONMENT=public" >> tmpsourcemesh
  echo "export TF_VAR_client_secret=\$ARM_CLIENT_SECRET" >> tmpsourcemesh
  echo "export TF_VAR_client_id=\$ARM_CLIENT_ID" >> tmpsourcemesh
  mv tmpsourcemesh ../../azure/sourceme.sh
  rm sp.json
fi
source ../../azure/sourceme.sh
echo "Running terraform to create other resources (stateaccounts etc)"
terraform init 
terraform apply 