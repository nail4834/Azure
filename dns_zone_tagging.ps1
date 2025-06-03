# Define variables
$ExcelFilePath = "C:\Users\rajeshkan\Desktop\Azure-25\dns_zones.xlsx"  # Replace with your actual Excel file path
$SheetName = "Sheet1"  # Replace with the sheet name where data is stored

# Import module for Excel handling
Import-Module ImportExcel

# Connect to Azure
# Connect-AzAccount

# Read data from Excel
$DNSZonesData = Import-Excel -Path $ExcelFilePath -WorksheetName $SheetName

# Loop through each row in the Excel file and tag DNS zones
foreach ($Row in $DNSZonesData) {
    $SubscriptionId = $Row.SubscriptionId
    $ResourceGroupName = $Row.ResourceGroupName
    $DNSZoneName = $Row.DNSZoneName
    $TagKey = $Row.TagKey
    $TagValue = $Row.TagValue
    
    Select-AzSubscription -SubscriptionId $SubscriptionId
    
    $DNSZone = Get-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $DNSZoneName
    
    if ($DNSZone) {
        $Tags = $DNSZone.Tags
        if (-not $Tags) { $Tags = @{} }  # Ensure tags exist
        
        $Tags[$TagKey] = $TagValue
        Set-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $DNSZoneName -Tag $Tags
        
        Write-Output "Tagged DNS Zone: $DNSZoneName with $TagKey=$TagValue"
    } else {
        Write-Output "DNS Zone: $DNSZoneName not found in Resource Group: $ResourceGroupName"
    }
}

Write-Output "Tagging process completed."
