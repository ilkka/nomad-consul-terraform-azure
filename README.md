# Consul backend Nomad cluster?

Let's see.

## How to

1. In the `bootstrap` directory, do `terraform init` and `terraform apply` to get the root RG, storage account and container for main terraform state.
1. Be sure to grab the storage account access key from the output!
1. Set the following environment variables in a shell:

   - `ARM_SUBSCRIPTION_ID`: Azure subscription ID from `az account show`

   - `ARM_TENANT_ID`: Azure tenant ID from `az account show`

   - `ARM_CLIENT_ID`: service principal ID from `az ad sp create-for-rbac --name Packer` _or_ from existing packer SP credentials

   - `ARM_CLIENT_SECRET`: service principal password from above, or `az ad sp credential reset --name Packer`

1. In `consul-image`, run `packer build consul.json` to build a Consul image
1. Grab the full slash-delimited image ID from `az image list`
1. In the root directory, `terraform init -backend-config="access_key=ACCESS-KEY-HERE"`
1. In the root directory, `terraform apply -var="consul_image_id=IMAGE-ID-HERE` to generate
