# Define variables
$ExcelFilePath = "C:\Users\rajeshkan\Desktop\Azure-25\resource_tags_remove.xlsx"  # Excel file path
$SheetName = "Sheet1"  # Name of the sheet containing data

# Import module for Excel handling
Import-Module ImportExcel

# Connect to Azure (Uncomment if required)
# Connect-AzAccount

# Read data from Excel
$ResourceData = Import-Excel -Path $ExcelFilePath -WorksheetName $SheetName

# Process tag removal in parallel with ThrottleLimit 10
$ResourceData | ForEach-Object -Parallel {
    # Define function inside parallel block
    function Remove-Tags {
        param (
            [Parameter(Mandatory = $true)]
            $Row
        )
        
        $SubscriptionId = $Row.SubscriptionId
        $ResourceGroupName = $Row.ResourceGroupName
        $ResourceName = $Row.ResourceName
        $ResourceType = $Row.ResourceType

        # Switch to the correct subscription
        Select-AzSubscription -SubscriptionId $SubscriptionId

        # Retrieve the resource
        $Resource = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceName $ResourceName -ResourceType $ResourceType -ErrorAction SilentlyContinue

        if ($Resource) {
            # Get existing tags
            $Tags = $Resource.Tags
            if ($Tags -and $Tags.ContainsKey("environment")) {
                # Remove the 'env' tag by setting it to $null
                $Tags["environment"] = $null
                
                # Update resource with modified tags
                Update-AzTag -ResourceId $Resource.ResourceId -Tag $Tags -Operation Merge
                
                Write-Output "Removed tag 'environment' from ${ResourceType}: ${ResourceName}"
            } else {
                Write-Output "No 'environment' tag found on ${ResourceType}: ${ResourceName}"
            }
        } else {
            Write-Output "${ResourceType}: ${ResourceName} not found in Resource Group: ${ResourceGroupName}"
        }
    }

    # Call function inside parallel block
    Remove-Tags -Row $_
} -ThrottleLimit 10

Write-Output "Tag removal process completed."
