param location string = resourceGroup().location
param deployStorageAccount bool

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' = if (deployStorageAccount) {
  name: 'teddybearstorage'
  location: location
  kind: 'StorageV2'
  sku: {
    name:'Standard_LRS'
  }
}

