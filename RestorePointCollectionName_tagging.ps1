# Define variables
$ExcelFilePath = "C:\Users\rajeshkan\Desktop\Azure-25\restore_point_collections_id.xlsx"  # Replace with your actual Excel file path
$SheetName = "Sheet1"  # Replace with the sheet name where data is stored

# Import module for Excel handling
Import-Module ImportExcel

# Connect to Azure
# Connect-AzAccount

# Read data from Excel
$RestorePointCollectionsData = Import-Excel -Path $ExcelFilePath -WorksheetName $SheetName

# Loop through each row in the Excel file and tag Restore Point Collections
foreach ($Row in $RestorePointCollectionsData) {
    $SubscriptionId = $Row.SubscriptionId
    $ResourceGroupName = $Row.ResourceGroupName
    $RestorePointCollectionName = $Row.RestorePointCollectionName
    $TagKey = $Row.TagKey
    $TagValue = $Row.TagValue
    
    Select-AzSubscription -SubscriptionId $SubscriptionId
    
    $RestorePointCollection = Get-AzRestorePointCollection -ResourceGroupName $ResourceGroupName -Name $RestorePointCollectionName
    
    if ($RestorePointCollection) {
        $Tags = $RestorePointCollection.Tags
        if (-not $Tags) { $Tags = @{} }  # Ensure tags exist
        
        $Tags[$TagKey] = $TagValue
        Update-AzRestorePointCollection -ResourceGroupName $ResourceGroupName -Name $RestorePointCollectionName -Tag $Tags
        
        Write-Output "Tagged Restore Point Collection: $RestorePointCollectionName with $TagKey=$TagValue"
    } else {
        Write-Output "Restore Point Collection: $RestorePointCollectionName not found in Resource Group: $ResourceGroupName"
    }
}

Write-Output "Tagging process completed."
