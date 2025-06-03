$Import = Import-Csv -Path 'E:\azdisk.csv'

foreach($I in $Import)
{
	$disk = $I.disk_name
	$rs_group = $I.r_group
	$brand = $I.brand
	$loc = $I.location
	$sub = $I.subcription
	$des = $I.description
	$typ = $I.storage_type
	$sec_ty =$I.security_type
	
	

az disk update --name $disk --resource-group $rs_group --set tags.brand=$brand tags.location=$loc tags.subcription=$sub tags.description=$des tags."storage type"=$typ tags."security type"=$sec_ty

}
