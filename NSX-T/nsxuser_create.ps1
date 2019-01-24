# Parameter help description
[string]$domain = "corp.local"
[string]$nsxuser = "svc_nsx"
[string]$vcentername = "vc-01a.corp.local"


# NSX_T user
$nsxt_user = "$domain\$nsxuser"

# NSX_T permissions
$nsxt_role = "nsxt_permissions"
 
#Privileges to assign to role $nsxt_role

$roleidfile = "nsx_role_ids.txt"

$nsxt_privileges = @()
Get-Content $roleidfile | Foreach-Object {
    $nsxt_privileges += $_
}


New-VIRole -Name $nsxt_role -Privilege (Get-VIPrivilege -id $nsxt_privileges) | out-null
$rootFolder = Get-Folder -NoRecursion

New-VIPermission -Entity $rootFolder -Principal $nsxt_user -Role $nsxt_role -Propagate:$true | Out-Null
