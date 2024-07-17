@description('The location into which your Azure resources should be deployed.')
param location string = resourceGroup().location

@description('Select the type of environment you want to provision. Allowed values are Production and Test.')
@allowed([
  'Production'
  'Test'
])
param environmentType string

@description('The pipeline Service Pricincipal Object Id to be permit read secrets in Vault Key.')
param pipelineServicePrincipalObjectId string

@description('The Secrect Name of KeyValt to deployment key')
param keyVaultSecrectName string = 'TestandoBicepStaticWebAppDeploymentKey'


var staticWebAppName = 'testando-${uniqueString(resourceGroup().id)}'
var keyVaultName = 'testando-vault-${ substring(uniqueString(resourceGroup().id),0,6)}'

var environmentConfigurationMap = {
  Production: {
    staticWebApp: {
      sku: {
        name: 'Free'
      }
    }
  }
  Test: {
    staticWebApp: {
      sku: {
        name: 'Free'
      }
    }
  }
}

resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: staticWebAppName
  location: location
  sku: environmentConfigurationMap[environmentType].staticWebApp.sku
  properties:{}
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: true
    accessPolicies: [
      {
        objectId: pipelineServicePrincipalObjectId
        permissions: {
          secrets: [
            'list', 'get'
          ]
        }
        tenantId: tenant().tenantId
      }

    ]
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
  }
}

resource keyVaultSecrect 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: keyVaultSecrectName
  properties: {
    value: staticWebApp.listSecrets().properties.apiKey
  }
}


output staticAppHostName string = staticWebApp.properties.defaultHostname
output keyVaultName string = keyVault.name
output keyVaultSecrectName string = keyVaultSecrect.name
