using './main.bicep'

// Development sample: replace these values before deployment; the VNet and subnet must already exist.
param storageAccountName = 'storagehondadevbicep'
param location = 'westeurope'
param virtualNetworkResourceId = '/subscriptions/6919957e-e2ea-4bb4-9bfa-91af4af5e4ff/resourceGroups/rg-kohera-jdb-sandbox/providers/Microsoft.Network/virtualNetworks/vnet-honda-dev'
param privateEndpointSubnetName = 'Snet-honda-dev-priv-end'

// Uncomment to allow selected PUBLIC source IP ranges via the storage firewall.
// param allowedPublicIpRanges = ['<your-public-ip>/32']
