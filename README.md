# Databricks Terraform with Storage Account and VNet

## What is this?

This is a basic Terraform implementation for deploying Azure Databricks.  It includes a Storage Account which is configured to only be accessible within a virtual network to which Databricks will also be connected.  Connectivity is provided via the use of service endpoints.

More info [here](https://www.databricks.com/blog/2020/02/28/securely-accessing-azure-data-sources-from-azure-databricks.html)

## What you need to run this:

- Terraform CLI
- A service principal
- A file called `dev.env` containing the following:
    ```
    export ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
    export ARM_TENANT_ID="<azure_subscription_tenant_id>"
    export ARM_CLIENT_ID="<service_principal_appid>"
    export ARM_CLIENT_SECRET="<service_principal_password>"
    ```
- A resource group
- The service principal should have at least Contributor rights in the resource group
- A file called `tfvars.vars` containing the following:
    ```
    resource_group_name = "<resource group name>"
    prefix = "<a prefix for your resources>"

# Running this

Everything can be done with one script `./deploy_infra.sh`

