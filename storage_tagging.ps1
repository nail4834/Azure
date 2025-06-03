# Define variables
$ExcelFilePath = "C:\Users\rajeshkan\Desktop\Azure-25\storage_id.xlsx"  # Replace with your actual Excel file path
$SheetName = "Sheet1"  # Replace with the sheet name where data is stored

# Import module for Excel handling
Import-Module ImportExcel

# Connect to Azure
# Connect-AzAccount

# Read data from Excel
$StorageAccountsData = Import-Excel -Path $ExcelFilePath -WorksheetName $SheetName

# Loop through each row in the Excel file and tag storage accounts
foreach ($Row in $StorageAccountsData) {
    $SubscriptionId = $Row.SubscriptionId
    $ResourceGroupName = $Row.ResourceGroupName
    $StorageAccountName = $Row.StorageAccountName
    $TagKey = $Row.TagKey
    $TagValue = $Row.TagValue
    
    Select-AzSubscription -SubscriptionId $SubscriptionId
    
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    
    if ($StorageAccount) {
        $Tags = $StorageAccount.Tags
        if (-not $Tags) { $Tags = @{} }  # Ensure tags exist
        
        $Tags[$TagKey] = $TagValue
        Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Tag $Tags
        
        Write-Output "Tagged Storage Account: $StorageAccountName with $TagKey=$TagValue"
    } else {
        Write-Output "Storage Account: $StorageAccountName not found in Resource Group: $ResourceGroupName"
    }
}

Write-Output "Tagging process completed."