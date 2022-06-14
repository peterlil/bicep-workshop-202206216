# Create a storage account and store a key in Key Vault

In this exercise you should create the following Azure resources using bicep:

* A resource group (hint - use deployment on subscription scope)
* A Key Vault
* A Storage Account

When the Storage Account is created, you should store one of the access keys as a secret in the Key Vault you just created, all using Bicep.

Feel free to try this one completely on your own. If you need some guidace you can either look at a complete solution [in the custom-exercise folder](https://github.com/peterlil/bicep-workshop-202206216/tree/main/custom-excersice) or follow the steps outlined below.

## Step by step solution

### Step 1 - Creating the resource group

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
  -p location='westeurope' rgName='bicep-labs-rg'
```

### Step 2 - Deploy Key Vault to the resource group

It's a good idea to deploy Key Vault through its own Bicep module so the code remains simple and easily readable. Create a new folder called `modules` in the folder where you put the file `main.bicep`. In the folder `modules`, create a new file named `key-vault.bicep`.

Write the bicep code to deploy the Key Vault Azure resource or copy and paste for the code below. 

```bicep
param location string = resourceGroup().location
param kvName string = 'MyKeyVault'

// objectId is the AAD objectId of the user deploying the template
@secure()
param objectId string

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true // allow ARM to access the key vault
    accessPolicies:[
      {
        objectId: objectId
        permissions:{
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}
```

Now you need to make sure the module is deployed when you deploy `main.bicep`. It requires that `main.bicep` uses a `module`-section as per below.

```bicep
targetScope = 'subscription'

param location string = 'westeurope'
param rgName string = 'bicep-lab'

// added a parameter for the name of the key vault
param keyVaultName string = 'bicep-labs-keyvault'

// added a parameter for the objectId, i.e. the AAD user that should be granted
// permissions to the key vault. The parameter is decorated with the @secure()
// decorator so the objectId of the user will not turn up on logs and such.
@secure()
param objectId string


resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  location: location
  name: rgName
}

// defining the module for deploying key vault
module kv 'modules/key-vault.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'key-vault'
  params: {
    location: location
    objectId: objectId
    kvName: keyVaultName
  }
}
```

To deploy the Bicep template, we need now to pass in the Key Vault name as parameter as well. It's probably time to store all parameter values in a parameter file. Create a file named `main.parameters.json` in the same folder as `main.bicep` and copy and paste the content from below.

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "location": {
        "value": "westeurope"
      },
      "rgName": {
        "value": "bicep-labs-rg"
      },
      "keyVaultName": {
        "value": "mykeyvault332"
      }
    }
  }
```

Now the deployment command needs to be adjusted to use the parameter file instead, and we need to use Azure CLI to get the objectId of the user deploying the template.

_Note: Make sure you replace `alias@domain.com` with your account name before you run the script._

```shell
# Get the current user's object_id
objectId=$(az ad user show --id alias@domain.com --query id -o tsv)
# Deploy the template
az deployment sub create \
  -l 'westeurope' \
  -f main.bicep \
  -p 'main.parameters.json' \
     objectId=$objectId
```

### Step 3 - Deploy the storage account and store a key in Key Vault

The deployment of the storage account is best done in it's own module, create a new file in the `modules` folder called `storage-account.bicep`.

Write and/or copy and paste from below the resource-definition of the storage account in to the newly created file.

```bicep
param storageAccountName string
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
    name: storageAccountName
    location: location
    sku: {
        name: 'Standard_LRS'
    }
    kind: 'StorageV2'
    properties: {
        accessTier: 'Hot'
    }
}
```

The new module needs to be called from `main.bicep` and we need to add a new parameter for the storage account name.

Add the module-definition to the end of `main.bicep`.
```bicep
module storage 'modules/storage-account.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'storage-account'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}
```

Add the parameter for the storage account name below the existing parameters in `main.bicep`.
Change the default name to another name of your choosing.
```bicep
param storageAccountName string = 'defaultname'
```

To finish off the creation of the storage account, let's add the storage account name as a parameter in the parameter file. The whole file should look something like this.

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "value": "westeurope"
    },
    "rgName": {
      "value": "bicep-labs-rg"
    },
    "keyVaultName": {
      "value": "mykeyvault332"
    },
    "storageAccountName": {
      "value": "mystorage333"
    }
  }
}
```

The storage account should now be deployed with the rest of the resources, but we still need to get hold of the storage account key and store it in Key Vault.

To do that, it's helpful to know that a Key Vault secret is an Azure resource by itself, that also is deployable through Bicep.

In `storage-account.bicep` you will need to get a reference to the Key Vault in order to deploy a child resource (the secret). Let's see how that looks.

```bicep
param storageAccountName string
param location string

// add a parameter with the Key Vault name so you can reference it in the bicep template.
param keyVaultName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
    name: storageAccountName
    location: location
    sku: {
        name: 'Standard_LRS'
    }
    kind: 'StorageV2'
    properties: {
        accessTier: 'Hot'
    }
}

// add a resource definition of a Key Vault with the 'existing' keyword to get 
// a reference to the Key Vault created in the other module.
resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

// add a resource definition for a vault secret and use the symbolic name
// of the storage account to get a secret value.
resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'storage-account-key'
  parent: kv 
  properties: {
    value: storageAccount.listKeys().keys[0].value
  }
}
```

Now you need to pass in the name of the Key Vault to storage account module in `main.bicep`. You already have the name in a parameter (storageAccountName), but it's smarter to create an output with the name from the Key Vault-module to use as the parameter value for the storage account module. That way Bicep will understand that the storage account module depends on the key vault module, and will always deploy the modules in the correct order. 

To add an output value in the key vault module, add this line to end of `key-vault.bicep`.

```bicep
output keyVaultName string = kv.name
```

To use the output from the key vault module in `main.bicep`, change the module definition of the storage account to this:
```bicep
module storage 'modules/storage-account.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'storage-account'
  params: {
    keyVaultName: kv.outputs.keyVaultName // reference the key vault module to get the name
    location: location
    storageAccountName: storageAccountName
  }
}
```

Save all files, because now you are finished and you can run the final deployment.

_Note: Make sure you replace `alias@domain.com` with your account name before you run the script._

```shell
# Get the current user's object_id
objectId=$(az ad user show --id alias@domain.com --query id -o tsv)
# Deploy the template
az deployment sub create \
  -l 'westeurope' \
  -f main.bicep \
  -p 'main.parameters.json' \
     objectId=$objectId
```
