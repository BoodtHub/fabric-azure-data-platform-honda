targetScope = 'resourceGroup'

@description('Globally unique lowercase storage account name (3-24 characters). Follow the project naming convention.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Region of the resource group and existing VNet; the private endpoint must be in the VNet region.')
param location string = resourceGroup().location

@description('Resource ID of the existing VNet containing the private endpoint subnet.')
param virtualNetworkResourceId string

@description('Name of an existing subnet in that VNet for the blob private endpoint.')
param privateEndpointSubnetName string

@description('Optional public IPv4 CIDRs for storage firewall rules. Empty disables the public endpoint. Do not use 0.0.0.0/0.')
param allowedPublicIpRanges string[] = []

@description('Storage redundancy; ensure the selected SKU is available in the region.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
])
param storageSku string = 'Standard_LRS'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: empty(allowedPublicIpRanges) ? 'Disabled' : 'Enabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
      ipRules: [for ipRange in allowedPublicIpRanges: {
        action: 'Allow'
        value: ipRange
      }]
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource rawfiles 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'rawfiles'
  properties: {
    publicAccess: 'None'
  }
}

resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-${storageAccountName}-blob'
  location: location
  properties: {
    subnet: {
      id: '${virtualNetworkResourceId}/subnets/${privateEndpointSubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

output storageAccountName string = storage.name
output blobEndpoint string = storage.properties.primaryEndpoints.blob
output containerName string = rawfiles.name
output privateEndpointId string = blobPrivateEndpoint.id
