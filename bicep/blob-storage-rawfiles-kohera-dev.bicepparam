using './main.bicep'

// Development sample: replace these values before deployment; the VNet and subnet must already exist.
param storageAccountName = 'storageOBMEU7dev'
param location = 'westeurope'

// Uncomment to allow selected PUBLIC source IP ranges via the storage firewall.
// param allowedPublicIpRanges = ['<your-public-ip>/32']
