# List your 5 subscription IDs here
$subscriptionIds = @(
    "ba5d0b77-338d-4b26-a535-5943af00eeb8",
    "29f03b62-3e53-43a5-9862-621ba7b8cca9",
    "0a701e06-76b1-4951-b7f5-1c539ca9e529",
    "3ac652ad-b252-4cf1-a95c-6e091aeec8d5"
)

# Connect to Azure
# Connect-AzAccount

# Initialize a list to hold all results
$allResults = @()

foreach ($subId in $subscriptionIds) {
    # Set current subscription context
    Set-AzContext -SubscriptionId $subId -ErrorAction Stop

    # Get all VMs in current subscription with status
    $vms = Get-AzVM -Status

    # Filter VMs running Ubuntu with version less than 22.04
    $filteredVMs = $vms | Where-Object {
        $_.StorageProfile.ImageReference.Publisher -eq "Canonical" -and
        $_.StorageProfile.ImageReference.Offer -like "Ubuntu*" -and
        ($_sku = $_.StorageProfile.ImageReference.Sku) -and
        ($_sku -match "^(\d{2}\.\d{2})") -and
        ([version]$matches[1]) -lt [version]"22.04"
    }

    foreach ($vm in $filteredVMs) {
        $nicIds = $vm.NetworkProfile.NetworkInterfaces.Id

        $privateIp = $null
        $publicIp = $null

        foreach ($nicId in $nicIds) {
            $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name ($(Split-Path $nicId -Leaf))

            foreach ($ipConfig in $nic.IpConfigurations) {
                if (-not $privateIp) {
                    $privateIp = $ipConfig.PrivateIpAddress
                }

                if ($ipConfig.PublicIpAddress) {
                    $publicIpResourceId = $ipConfig.PublicIpAddress.Id
                    $publicIpResourceName = $(Split-Path $publicIpResourceId -Leaf)
                    $publicIpObj = Get-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $publicIpResourceName
                    if ($publicIpObj.IpAddress) {
                        $publicIp = $publicIpObj.IpAddress
                    }
                }
            }
        }

        # Add to allResults array
        $allResults += [PSCustomObject]@{
            SubscriptionId    = $subId
            Name              = $vm.Name
            ResourceGroupName = $vm.ResourceGroupName
            Location          = $vm.Location
            OSVersion         = $vm.StorageProfile.ImageReference.Sku
            PrivateIP         = $privateIp
            PublicIP          = $publicIp
        }
    }
}

# Display all results in a table
$allResults | Format-Table -AutoSize
