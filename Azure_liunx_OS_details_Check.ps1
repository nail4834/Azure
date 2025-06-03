# List your actual subscription IDs
$subscriptionIds = @(
    "ba5d0b77-338d-4b26-a535-5943af00eeb8",
    "29f03b62-3e53-43a5-9862-621ba7b8cca9",
    "0a701e06-76b1-4951-b7f5-1c539ca9e529",
    "3ac652ad-b252-4cf1-a95c-6e091aeec8d5"
)

# Connect to Azure
# Connect-AzAccount

$allResults = @()
$skippedVMs = @()

foreach ($subId in $subscriptionIds) {
    Write-Host "`nSwitching to subscription: $subId" -ForegroundColor Cyan
    Set-AzContext -SubscriptionId $subId -ErrorAction Stop

    # Get Canonical Ubuntu VMs
    $vms = Get-AzVM -Status | Where-Object {
        $_.StorageProfile.ImageReference.Publisher -eq "Canonical" -and
        $_.StorageProfile.ImageReference.Offer -like "Ubuntu*"
    }

    foreach ($vm in $vms) {
        $vmName = $vm.Name
        $rgName = $vm.ResourceGroupName
        $powerState = ($vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus

        Write-Host "Checking VM: $vmName [$powerState]" -ForegroundColor Yellow

        if ($powerState -ne "VM running") {
            Write-Warning "$vmName is not running. Skipped."
            $skippedVMs += "$vmName - $powerState"
            continue
        }

        try {
            $script = @"
lsb_release -r
"@
            $runResult = Invoke-AzVMRunCommand -ResourceGroupName $rgName -Name $vmName `
                -CommandId 'RunShellScript' -ScriptString $script -ErrorAction Stop

            $outputText = $runResult.Value[0].Message.Trim()
            Write-Host "Output from $vmName: $outputText"

            if ($outputText -match "Release:\s+(\d+\.\d+)") {
                $actualVersion = [version]$matches[1]

                if ($actualVersion -lt [version]"22.04") {
                    # Get IPs
                    $nicIds = $vm.NetworkProfile.NetworkInterfaces.Id
                    $privateIp = $null
                    $publicIp = $null

                    foreach ($nicId in $nicIds) {
                        $nic = Get-AzNetworkInterface -ResourceGroupName $rgName -Name ($(Split-Path $nicId -Leaf))
                        foreach ($ipConfig in $nic.IpConfigurations) {
                            if (-not $privateIp) {
                                $privateIp = $ipConfig.PrivateIpAddress
                            }
                            if ($ipConfig.PublicIpAddress) {
                                $publicIpId = $ipConfig.PublicIpAddress.Id
                                $publicIpName = $(Split-Path $publicIpId -Leaf)
                                $publicIpObj = Get-AzPublicIpAddress -ResourceGroupName $rgName -Name $publicIpName
                                if ($publicIpObj.IpAddress) {
                                    $publicIp = $publicIpObj.IpAddress
                                }
                            }
                        }
                    }

                    # Store result
                    $allResults += [PSCustomObject]@{
                        SubscriptionId    = $subId
                        Name              = $vmName
                        ResourceGroupName = $rgName
                        Location          = $vm.Location
                        ActualOSVersion   = $actualVersion.ToString()
                        PrivateIP         = $privateIp
                        PublicIP          = $publicIp
                    }
                } else {
                    Write-Host "$vmName is running Ubuntu $actualVersion — OK"
                }
            } else {
                Write-Warning "Could not parse OS version for $vmName. Output: $outputText"
                $skippedVMs += "$vmName - No match for lsb_release"
            }

        } catch {
            Write-Warning "Error processing $vmName: $($_.Exception.Message)"
            $skippedVMs += "$vmName - RunCommand failed"
        }
    }
}

# Final output
Write-Host "`n==== VMs running Ubuntu version < 22.04 ====" -ForegroundColor Green
$allResults | Format-Table -AutoSize

Write-Host "`n==== Skipped or Failed VMs ====" -ForegroundColor Red
$skippedVMs | ForEach-Object { Write-Host $_ }

# Optional: Export results
# $allResults | Export-Csv "./UbuntuVMs_Under_2204.csv" -NoTypeInformation
# $skippedVMs | Out-File "./SkippedVMs.log"
