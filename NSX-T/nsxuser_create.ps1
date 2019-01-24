# Parameter help description
[string]$domain = "vsphere.local"
[string]$nsxtuser = "svc_nsx"
[string]$vcentername = "vc-01a.corp.local"


# NSX_T user
$nsxt_user = "$domain\$nsxtuser"

# NSX_T permissions
$nsxt_role = "nsxt_permissions"
 
#Roles for NSX-T 2.3+
$nsxt_privileges = @(
'Extension.Register',
'Extension.Update',
'Extension.Unregister',
'Sessions.TerminateSession',
'Sessions.ValidateSession',
'Sessions.GlobalMessage',
'Sessions.ImpersonateUser',
'Host.Local.CreateVM',
'Host.Local.ReconfigVM',
'Host.Local.DeleteVM',
'Host.Config.Maintenance',
'Task.Create',
'Task.Update',
'ScheduledTask.Create',
'ScheduledTask.Delete',
'ScheduledTask.Run',
'ScheduledTask.Edit',
'Global.CancelTask',
'Authorization.ReassignRolePermissions',
'Resource.AssignVMToPool',
'Resource.AssignVAppToPool',
'Network.Assign',
'VirtualMachine.GuestOperations.Query',
'VirtualMachine.GuestOperations.Modify',
'VirtualMachine.GuestOperations.Execute',
'VirtualMachine.GuestOperations.QueryAliases',
'VirtualMachine.GuestOperations.ModifyAliases',
'VirtualMachine.Config.Rename',
'VirtualMachine.Config.Annotation',
'VirtualMachine.Config.AddExistingDisk',
'VirtualMachine.Config.AddNewDisk',
'VirtualMachine.Config.RemoveDisk',
'VirtualMachine.Config.RawDevice',
'VirtualMachine.Config.HostUSBDevice',
'VirtualMachine.Config.CPUCount',
'VirtualMachine.Config.Memory',
'VirtualMachine.Config.AddRemoveDevice',
'VirtualMachine.Config.EditDevice',
'VirtualMachine.Config.Settings',
'VirtualMachine.Config.Resource',
'VirtualMachine.Config.UpgradeVirtualHardware',
'VirtualMachine.Config.ResetGuestInfo',
'VirtualMachine.Config.ToggleForkParent',
'VirtualMachine.Config.AdvancedConfig',
'VirtualMachine.Config.DiskLease',
'VirtualMachine.Config.SwapPlacement',
'VirtualMachine.Config.DiskExtend',
'VirtualMachine.Config.ChangeTracking',
'VirtualMachine.Config.QueryUnownedFiles',
'VirtualMachine.Config.ReloadFromPath',
'VirtualMachine.Config.QueryFTCompatibility',
'VirtualMachine.Config.MksControl',
'VirtualMachine.Config.ManagedBy',
'VirtualMachine.Provisioning.Customize',
'VirtualMachine.Provisioning.Clone',
'VirtualMachine.Provisioning.PromoteDisks',
'VirtualMachine.Provisioning.CreateTemplateFromVM',
'VirtualMachine.Provisioning.DeployTemplate',
'VirtualMachine.Provisioning.CloneTemplate',
'VirtualMachine.Provisioning.MarkAsTemplate',
'VirtualMachine.Provisioning.MarkAsVM',
'VirtualMachine.Provisioning.ReadCustSpecs',
'VirtualMachine.Provisioning.ModifyCustSpecs',
'VirtualMachine.Provisioning.DiskRandomAccess',
'VirtualMachine.Provisioning.DiskRandomRead',
'VirtualMachine.Provisioning.FileRandomAccess',
'VirtualMachine.Provisioning.GetVmFiles',
'VirtualMachine.Provisioning.PutVmFiles',
'VirtualMachine.Inventory.Create',
'VirtualMachine.Inventory.CreateFromExisting',
'VirtualMachine.Inventory.Register',
'VirtualMachine.Inventory.Delete',
'VirtualMachine.Inventory.Unregister',
'VirtualMachine.Inventory.Move',
'VApp.ResourceConfig',
'VApp.InstanceConfig',
'VApp.ApplicationConfig',
'VApp.ManagedByConfig',
'VApp.Export',
'VApp.Import',
'VApp.ExtractOvfEnvironment',
'VApp.AssignVM',
'VApp.AssignResourcePool',
'VApp.AssignVApp',
'VApp.Clone',
'VApp.Create',
'VApp.Delete',
'VApp.Unregister',
'VApp.Move',
'VApp.PowerOn',
'VApp.PowerOff',
'VApp.Suspend',
'VApp.Rename'
)


# PRE CHECK
# VCSA has no APIS for SSO features in VCSA. Therefore an account must be manually made otherwise it does not work. I will do a check and throw before doing this to ensure user has gone and made a manual user. Ugh!
# If AD is already setup this will work, I believe.

$existingaccounts = get-viaccount -Domain $domain
$existing = $existingaccounts | ? {$_.name -eq $nsxt_user}

if (!$existing){
    write-host -ForegroundColor Red "There is no account $nsxt_user created. Please create one manually and harass VMware for a new cmdlet and APIs!"

    write-host -ForegroundColor Red "To create a local vCenter user:
    `n 1. Menu -> Administration
    `n 2. Single Sign On -> Users and Groups
    `n 3. Domain = vSphere.local
    `n 4. Add Users and match $nsxtuser
    `n 5. Rerun the script "

}
else {
    
    $rootFolder = Get-Folder -NoRecursion
    
    #validate if role already exists through previous install.
    $existingrole = get-virole -name $nsxt_role -ErrorAction silentlycontinue

    if ($existingrole){
        $guid = (new-guid).Guid.substring(0,6)
        write-host -ForegroundColor Green "Found existing role named $nsxt_role. Creating a new role $nsxt_role-$guid and assigning to $nsxt_user"
        New-VIRole -Name "$nsxt_role-$guid" -Privilege (Get-VIPrivilege -id $nsxt_privileges) | out-null

        New-VIPermission -Entity $rootFolder -Principal $nsxt_user -Role $nsxt_role -Propagate:$true | Out-Null
    }
    else {
        write-host -ForegroundColor Green "Creating role $nsxt_role - Assigning to $nsxt_user"
        New-VIRole -Name $nsxt_role -Privilege (Get-VIPrivilege -id $nsxt_privileges) | out-null
        
        New-VIPermission -Entity $rootFolder -Principal $nsxt_user -Role $nsxt_role -Propagate:$true | Out-Null
    } 

}

