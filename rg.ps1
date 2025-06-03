
$Import = Import-Csv -Path 'E:\aztagtest.csv'

foreach($I in $Import)

{
	$server = $I.server
	$sub = $I.subcription
	

Get-AzResource -Name $server -ResourceType "Microsoft.Compute/VirtualMachines" | New-AzTag -Tag @{ 'subcription' = $sub }

}
