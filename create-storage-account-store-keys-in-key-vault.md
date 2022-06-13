# Create a storage account and store a key in Key Vault

```bicep
targetScope = subscription

resource rg = 'Microsoft.Resources/resourceGroups@2020-10-01'

//resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
//    name: 'toylaunchstorage'
//    location: 'westeurope'
//    sku: {
//        name: 'Standard_LRS'
//    }
//    kind: 'StorageV2'
//    properties: {
//        accessTier: 'Hot'
//    }
//}
```
