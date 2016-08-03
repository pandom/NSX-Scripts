## Distributed Firewall rule validator ##
## Author: Anthony Burke t:@pandom_ b:networkinferno.net
## version 1.0
## January 2015
#-------------------------------------------------- 
# ____   __   _  _  ____  ____  __ _  ____  _  _ 
# (  _ \ /  \ / )( \(  __)(  _ \(  ( \/ ___)( \/ )
#  ) __/(  O )\ /\ / ) _)  )   //    /\___ \ )  ( 
# (__)   \__/ (_/\_)(____)(__\_)\_)__)(____/(_/\_)
#     PowerShell extensions for NSX for vSphere
#--------------------------------------------------
#USAGE: On execution of the script either change the $vmname attribute to the specific VM. 
param (
$vmname = "melb-log-0",
# WARNING - this script uses match. It will pull out details of ALL VMs that match the string in $VMNAME. An exact match will need to be the entire VM's name.
$vmactual = (Get-Vm | ? {$_.name -match "$vmname"})
)
#Pulls VM filter information include VM-name and MAC address
write-host -foregroundcolor "Green" "$vmactual Firewall filter and VM IPs"
Get-Vm $vmactual | Select Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}} | ft -autosize -wrap
Get-Vm $vmactual | Get-NsxCliDfwFilter

#Pulls any related address sets and resolves them.
write-host -foregroundcolor "Green" "Resolving objects applied to $vmactual "
Get-Vm $vmactual | Get-NsxCliDfwAddrSet | ft -wrap -autosize
#Outputs ruletable installed onto the vNIC

write-host -foregroundcolor "Green" "Output of all rules"
get-vm $vmactual | Get-NsxCliDfwRule | ft -wrap -autosize RuleID,service,Source,Destination,Port
