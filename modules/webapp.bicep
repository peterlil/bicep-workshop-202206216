

param location string = resourceGroup().location

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: 'toy-product-launch-plan'
  location: location
  sku:{
    name: 'F1'
  }
}

resource appServiceApp 'Microsoft.Web/sites@2021-03-01' = {
  name: 'toy-product-aunch-1'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

output url string = appServiceApp.properties.defaultHostName

