# Create a storage account and store a key in Key Vault

In this exercise you should create the following Azure resources using bicep:

* A resource group (hint - use deployment on subscription scope)
* A Key Vault
* A Storage Sccount

When the Storage Account is created, you should store one of the access keys as a secret in the Key Vault you just created, all using Bicep.

Feel free to try this one completely on your own. If you need some guidace you can either look at a complete solution [in the custom-exercise folder](https://github.com/peterlil/bicep-workshop-202206216/tree/main/custom-excersice) or follow the steps outlined below.

## Step by step solution

### Creating the resource group

First you are going to need a resource group to deploy everything into. And as per the instructions, you need to create all Azure resources using bicep, so let's create a `main.bicep` and let's get going.

As we need to create the resource group, we need to be at one level higher, on the subscription level and deploy. This can be achieved with setting `scope` to `subscription` at the top of the file.

```bicep
targetScope = 'subscription'

param location string = 'westeurope'
param rgName string = 'bicep-lab'

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  location: location
  name: rgName
}
```

In order to deploy the resource group to Azure you will also need to run the right `az cli`-command to make it a subscription level deployment.

```shell
az deployment sub create \
  -l 'westeurope' \
  -f main.bicep \
  -p location='westeurope' name='bicep-labs-rg'
```

