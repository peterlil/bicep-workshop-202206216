param storageAccountName string
param location string
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

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'storage-account-key'
  parent: kv 
  properties: {
    value: storageAccount.listKeys().keys[0].value
  }
}
