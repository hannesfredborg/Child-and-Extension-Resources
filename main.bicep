@description('Name of Cosmos Database Acoount Name')
param cosmosDbAccountName string = 'cos-${uniqueString(resourceGroup().id)}'

@description('The azure region into wich the resources should be deployed')
param location string = resourceGroup().location

@description('Request Units Per Second')
param cosmosDbDataThroughput int = 400

@description('Container Name')
var cosmosDBContainerName = 'FlightTests'

@description('The configuration of the partition key to be used for partitioning data into multiple partitions')
var cosmosDBContainerPartitionKey = '/droneId'

@description('Database Name')
var cosmosDatabaseName = 'FlightTest'

@description('Name of the Law')
var logAnalyticsWorkspaceName = 'MoonLogs'

@description('Name of the diagnostic settings')
var cosmosDbAccountDiagnosticSettingsName = 'Send-logs-to-log-analytics'

@description('Name of the Storage Account')
var storageAccountName = 'moonshardstg'

var storageAccountBlobDiagnosticSettingsName = 'Send-logs-to-log-analytics'

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource sqlDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  name: cosmosDatabaseName
  parent: cosmosDbAccount
  properties: {
    resource: {
      id: cosmosDatabaseName
    }
    options: {
      throughput: cosmosDbDataThroughput
    }
  }
}

resource containers 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  name: '${cosmosDbAccountName}/${cosmosDatabaseName}/${cosmosDBContainerName}'
  dependsOn: [
    sqlDbDatabase
  ]
  properties:  {
    resource: {
      id: cosmosDBContainerName
      partitionKey: {
        kind: 'Hash'
        paths: [
          cosmosDBContainerPartitionKey
        ]
      }
    }
    options: {}
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource cosmosDbAccountDiagnostics'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: cosmosDbAccount
  name:cosmosDbAccountDiagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
    ]
  }
}

resource storageaccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName

  resource blobService 'blobServices' existing = {
    name: 'default'
  }
}

resource storageAccountBlobDiagnostics'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: storageaccount::blobService
  name: storageAccountBlobDiagnosticSettingsName
  properties: {
     workspaceId: logAnalyticsWorkspace.id
     logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
     ]
  }
}
