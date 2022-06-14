targetScope = 'subscription'

param location string = 'westeurope'
param rgName string = 'bicep-lab'
param keyVaultName string = 'bicep-labs-keyvault'
param storageAccountName string = 'peterlil99'
@secure()
param objectId string

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  location: location
  name: rgName
}

module kv 'modules/key-vault.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'key-vault'
  params: {
    location: location
    objectId: objectId
    kvName: keyVaultName
  }
}

module storage 'modules/storage-account.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'storage-account'
  params: {
    keyVaultName: kv.outputs.keyVaultName
    location: location
    storageAccountName: storageAccountName
  }
}

/*
objectId=$(az ad user show --id alias@domain.com --query id -o tsv)
az deployment sub create \
  -l 'westeurope' \
  -n 'full-deployment-'$(date "+%Y-%m-%d_%H%M%S") \
  -f main.bicep \
  -p main.parameters.json \
    objectId=$objectId \
  --verbose
*/



