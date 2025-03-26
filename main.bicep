@description('The name of the virtual machine')
param vmName string

@description('The location for all resources')
param location string = 'centralus'

@description('The availability zone for the VM')
param zone string = '1'

@description('The VM size')
param vmSize string = 'Standard_F8s_v2'

@description('The admin username for the VM')
param adminUsername string = 'windows-system-admin'

@description('The admin password for the VM')
@secure()
param adminPassword string

@description('PostgreSQL superuser password')
@secure()
param postgresPassword string = adminPassword

@description('PostgreSQL port')
param postgresPort string = '5432'

@description('PostgreSQL data directory')
param postgresDataDir string = 'C:\\Program Files\\PostgreSQL\\15\\data'

@description('The publisher of the image')
param imagePublisher string = 'MicrosoftWindowsServer'

@description('The offer of the image')
param imageOffer string = 'WindowsServer'

@description('The SKU of the image')
param imageSku string = '2019-datacenter-gensecond'

@description('The version of the image')
param imageVersion string = 'latest'

// Create Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${vmName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

// Create Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

// Create Public IP
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${vmName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    zones: [
      zone
    ]
  }
}

// Create Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/default'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
            properties: {
              deleteOption: 'Detach'
            }
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  zones: [
    zone
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        osType: 'Windows'
        name: '${vmName}_OsDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Install Java Runtime Environment
resource jdkExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm
  name: 'JavaRuntime'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'JavaRuntime'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      version: '17'
      distribution: 'temurin'
      jdk: true
    }
  }
}

// Install PostgreSQL
resource postgresExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm
  name: 'PostgreSQL'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'PostgreSQL'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      version: '15'
      password: postgresPassword
      port: postgresPort
      dataDir: postgresDataDir
    }
  }
  dependsOn: [
    jdkExtension
  ]
}
