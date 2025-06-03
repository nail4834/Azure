# Define variables
$ExcelFilePath = "C:\Users\rajeshkan\Desktop\Azure-25\disk_id.xlsx"  # Replace with your actual Excel file path
$SheetName = "Sheet1"  # Replace with the sheet name where data is stored

# Import module for Excel handling
Import-Module ImportExcel

# Connect to Azure
# Connect-AzAccount

# Read data from Excel
$DiskData = Import-Excel -Path $ExcelFilePath -WorksheetName $SheetName

# Loop through each row in the Excel file and tag disks
foreach ($Row in $DiskData) {
    $SubscriptionId = $Row.SubscriptionId
    $ResourceGroupName = $Row.ResourceGroupName
    $DiskName = $Row.DiskName
    $TagKey = $Row.TagKey
    $TagValue = $Row.TagValue
    
    Select-AzSubscription -SubscriptionId $SubscriptionId
    
    $Disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName
    
    if ($Disk) {
        $Tags = $Disk.Tags
        if (-not $Tags) { $Tags = @{} }  # Ensure tags exist
        
        $Tags[$TagKey] = $TagValue
        $Disk.Tags = $Tags
        Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName -Disk $Disk
        
        Write-Output "Tagged Disk: $DiskName with $TagKey=$TagValue"
    } else {
        Write-Output "Disk: $DiskName not found in Resource Group: $ResourceGroupName"
    }
}

Write-Output "Tagging process completed."

