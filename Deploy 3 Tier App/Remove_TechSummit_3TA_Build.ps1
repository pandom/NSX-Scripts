## Remove_TechSummit_3TA_Build ##
## Author: Anthony Burke t:@pandom_ b:networkinferno.net
## version 1.2
## January 2015
#-------------------------------------------------- 
# ____   __   _  _  ____  ____  __ _  ____  _  _ 
# (  _ \ /  \ / )( \(  __)(  _ \(  ( \/ ___)( \/ )
#  ) __/(  O )\ /\ / ) _)  )   //    /\___ \ )  ( 
# (__)   \__/ (_/\_)(____)(__\_)\_)__)(____/(_/\_)
#     PowerShell extensions for NSX for vSphere
#--------------------------------------------------

#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in 
#the Software without restriction, including without limitation the rights to 
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
#of the Software, and to permit persons to whom the Software is furnished to do 
#so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all 
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
#SOFTWARE.

### Note
#This powershell script should be considered entirely experimental and dangerous
#and is likely to kill babies, cause war and pestilence and permanently block all 
#your toilets.  Seriously - It's still in development,  not tested beyond lab 
#scenarios, and its recommended you dont use it for any production environment 
#without testing extensively!

# Removes 3TA from environment.
write-host -foregroundcolor "Green" "Halting all VMs attached to Logical Topology"
Get-NsxTransportZone | Get-NsxLogicalSwitch | Get-NsxBackingPortGroup | GET-Vm | Stop-Vm -Kill -confirm:$false
start-sleep 15
# Erases the VMDKs from the datastore
write-host -foregroundcolor "Green" "Deleting VMs from Disk"
Get-NsxTransportZone | Get-NsxLogicalSwitch | Get-NsxBackingPortGroup | GET-Vm | Remove-Vm -DeletePermanently -confirm:$false
# Deleting the logical router
write-host -foregroundcolor "Green" "Deleting Logical routers"
Get-NsxLogicalRouter | Remove-NsxLogicalRouter -confirm:$false
write-host -foregroundcolor "Green" "Deleting Edges"
# Deleting the NSX Edge gateway
Get-NsxEdge | Remove-NsxEdge -confirm:$false
write-host -foregroundcolor "Green" "20 seconds wait time for VMs to stop"
start-sleep 20
# Removes the logical Switches
write-host -foregroundcolor "Green" "Deleting Logical Switches"
get-NsxTransportZone | get-NsxLogicalSwitch | remove-NsxLogicalSwitch -confirm:$false
write-host -foregroundcolor "Green" "Erasing vApp"
get-vapp | remove-vapp -confirm:$false
#Kills microsegmentaiton of TS_3TA including the created Security Groups, IP Sets, and Firewall Section.
write-host -foregroundcolor "Green" "Putting out the fire"
get-NsxFirewallSection $FirewallSectionName | ? {$_.name -ne "default"} | remove-NsxFirewallSection -force -confirm:$False

write-host -foregroundcolor "Green" "Removing the intelligence (Security Groups)"
get-NsxSecurityGroup $WebSgName | Remove-NsxSecurityGroup -force -confirm:$False
get-NsxSecurityGroup $AppSgName | Remove-NsxSecurityGroup -force -confirm:$False
get-NsxSecurityGroup $DbSgName | Remove-NsxSecurityGroup -force -confirm:$False
get-NsxSecurityGroup $BooksSgName | Remove-NsxSecurityGroup -force -confirm:$False
get-nsxipset AppVIP_IpSet | Remove-NsxIpSet -force -confirm:$false
get-nsxipset InternalESG_IpSet| Remove-NsxIpSet -force -confirm:$false
Get-NsxIpSet Source_Network | Remove-NsxIpSet -force -confirm:$false
Get-NsxIpSet 'Source Test Network' | Remove-NsxIpSet -force -confirm:$false

write-host -foregroundcolor "Green" "Purge complete"
