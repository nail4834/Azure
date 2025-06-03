# Define variables
$ExcelFilePath = "C:\Users\rajeshkan\Desktop\Azure-25\resource_tags.xlsx"  # Replace with your actual Excel file path
$SheetName = "Sheet1"  # Replace with the sheet name where data is stored

# Import module for Excel handling
Import-Module ImportExcel

# Connect to Azure (Uncomment if required)
# Connect-AzAccount

# Read data from Excel
$ResourceData = Import-Excel -Path $ExcelFilePath -WorksheetName $SheetName

# Function to tag resources
function Tag-Resource {
    param ($Row)

    $SubscriptionId = $Row.SubscriptionId
    $ResourceGroupName = $Row.ResourceGroupName
    $ResourceName = $Row.ResourceName
    $ResourceType = $Row.ResourceType
    $TagKey = $Row.TagKey
    $TagValue = $Row.TagValue

    # Switch to the correct subscription
    Select-AzSubscription -SubscriptionId $SubscriptionId

    # Retrieve the resource
    $Resource = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceName $ResourceName -ResourceType $ResourceType -ErrorAction SilentlyContinue

    if ($Resource) {
        # Get existing tags
        $Tags = $Resource.Tags
        if (-not $Tags) { $Tags = @{} }

        # Update tags
        $Tags[$TagKey] = $TagValue
        Update-AzTag -ResourceId $Resource.ResourceId -Tag $Tags -Operation Merge

        Write-Output "Tagged ${ResourceType}: ${ResourceName} with ${TagKey}=${TagValue}"
    } else {
        Write-Output "${ResourceType}: ${ResourceName} not found in Resource Group: ${ResourceGroupName}"
    }
}

# Process tagging in parallel with ThrottleLimit 10
$ResourceData | ForEach-Object -Parallel {
    # Define the function within the parallel block so it’s available to the runspace
    function Tag-Resource {
        param ($Row)

        $SubscriptionId = $Row.SubscriptionId
        $ResourceGroupName = $Row.ResourceGroupName
        $ResourceName = $Row.ResourceName
        $ResourceType = $Row.ResourceType
        $TagKey = $Row.TagKey
        $TagValue = $Row.TagValue

        # Switch to the correct subscription
        Select-AzSubscription -SubscriptionId $SubscriptionId

        # Retrieve the resource
        $Resource = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceName $ResourceName -ResourceType $ResourceType -ErrorAction SilentlyContinue

        if ($Resource) {
            # Get existing tags
            $Tags = $Resource.Tags
            if (-not $Tags) { $Tags = @{} }

            # Update tags
            $Tags[$TagKey] = $TagValue
            Update-AzTag -ResourceId $Resource.ResourceId -Tag $Tags -Operation Merge

            Write-Output "Tagged ${ResourceType}: ${ResourceName} with ${TagKey}=${TagValue}"
        } else {
            Write-Output "${ResourceType}: ${ResourceName} not found in Resource Group: ${ResourceGroupName}"
        }
    }

    # Call the function within the parallel block
    Tag-Resource -Row $_
} -ThrottleLimit 10

Write-Output "Tagging process completed."
