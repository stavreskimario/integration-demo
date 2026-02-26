// ---------------------------------------------------------------------------
// Bicep template – Notes API  (Azure App Service, Linux, .NET 8)
// Deploy into an existing resource group with:
//   az deployment group create -g <RG_NAME> --template-file main.bicep --parameters appNameSuffix=<SUFFIX>
// ---------------------------------------------------------------------------

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('A unique suffix used to avoid naming collisions (e.g. your initials + random digits).')
param appNameSuffix string

@description('The App Service Plan SKU. Use F1 for the free tier.')
@allowed([
  'F1'
  'B1'
  'B2'
  'S1'
])
param skuName string = 'F1'

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------
var appServicePlanName = 'asp-notes-${appNameSuffix}'
var webAppName          = 'app-notes-${appNameSuffix}'

// ---------------------------------------------------------------------------
// App Service Plan  (Linux)
// ---------------------------------------------------------------------------
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true // required for Linux
  }
}

// ---------------------------------------------------------------------------
// Web App  (.NET 8, Linux)
// ---------------------------------------------------------------------------
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: skuName != 'F1' // alwaysOn not supported on free tier
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output resourceGroupName string = resourceGroup().name
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
