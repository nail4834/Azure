# Login to Azure
#Connect-AzAccount

# Get all Linux VMs
$vms = Get-AzVM | Where-Object { $_.StorageProfile.OsDisk.OsType -eq 'Linux' }

$results = @()

foreach ($vm in $vms) {
    $vmName = $vm.Name
    $resourceGroup = $vm.ResourceGroupName

    Write-Host "`nChecking OS version for VM: $vmName"

    try {
        # Avoid ambiguous 'Script' parameter by using full parameter names explicitly
        $runResult = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup `
                                           -VMName $vmName `
                                           -CommandId 'RunShellScript' `
                                           -Script @('cat /etc/os-release')

        # Clean and parse output
        $output = $runResult.Value[0].Message.Trim()
        $prettyName = ($output -split "`n" | Where-Object { $_ -like "PRETTY_NAME*" }) -replace 'PRETTY_NAME="?', '' -replace '"$', ''

        $results += [PSCustomObject]@{
            VMName        = $vmName
            ResourceGroup = $resourceGroup
            OSVersion     = $prettyName
        }
    } catch {
        $results += [PSCustomObject]@{
            VMName        = $vmName
            ResourceGroup = $resourceGroup
            OSVersion     = "ERROR: $($_.Exception.Message)"
        }
    }
}

# Display the results
$results | Format-Table -AutoSize
