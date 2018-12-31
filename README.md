# Consul backed Nomad cluster?

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

## TODO

- Scale sets start at 7 instances always, it seems. This throws Consul for a loop if it starts too soon, the leader probably just drops out and everybody's hella confused. Should wait maybe. Seems to work when doing this manually.
- There should be a VMSS for nomad workers too
- There should be a LB that includes both the workers and nomad servers
- The LB should target port 4646 from port 80
- Otherwise the network sg for the vnet should allow port 4646 from the internet
- Docker should be installed on the workers and the worker runner user should be in the docker group, otherwise no Docker driver
- Remember that Nomad services run this way are registered in Consul, therefore should be accessed through consul
- You can't access them unless you have a working LB strategy: https://www.hashicorp.com/blog/load-balancing-strategies-for-consul
- The instances in a VMSS won't know about their public IPs therefore the services won't get bound to the instance public IPs so you can't talk to them that way
- Azure LBs don't know about consul as such therefore you can't really route stuff to a service that way either
