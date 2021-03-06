
# Inputs is an attribute, so an equals sign is REQUIRED
inputs = {
  subscription_name  = split("/", path_relative_to_include())[0]
  location           = split("/", path_relative_to_include())[1]
  resourcegroup_name = split("/", path_relative_to_include())[2]
}

remote_state {
  backend = "azurerm"
  config = {
    storage_account_name = "${get_env("STORAGE_ACCOUNT_NAME", "terragrunt")}"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}
