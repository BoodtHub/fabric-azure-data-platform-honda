targetScope = 'resourceGroup'

@description('Globally unique lowercase storage account name (3-24 characters). Follow the project naming convention.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region where the storage account will be deployed.')
param location string = resourceGroup().location

@description('Optional public IPv4 CIDRs allowed through the storage firewall. Empty means no public IPs are allowed. Do not use 0.0.0.0/0.')
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
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
      ipRules: [
        for ipRange in allowedPublicIpRanges: {
          action: 'Allow'
          value: ipRange
        }
      ]
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

output storageAccountName string = storage.name
output blobEndpoint string = storage.properties.primaryEndpoints.blob
output containerName string = rawfiles.name
