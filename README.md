# Consul backend Nomad cluster?

Let's see.

## How to

1. In the `bootstrap` directory, do `terraform init` and `terraform apply` to get the root RG, storage account and container for main terraform state.
2. Be sure to grab the storage account access key from the output!
3. In the root directory, `terraform init -backend-config="access_key=ACCESS-KEY-HERE"`
4. In the root directory, `terraform apply` to generate
