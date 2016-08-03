## Log Insight Purage.
write-host -ForegroundColor Green "Purging"

Get-NsxFirewalLSection "Log Insight Cluster" | Remove-nsxfirewallsection -force -confirm:$false

get-nsxsecuritygroup | ? {$_.name -match ("SG-")} | remove-nsxsecuritygroup -confirm:$false -force

Get-NsxSecurityTag | ? {$_.name -match ("ST-LogInsight-Node")} | Remove-NsxSecurityTag -confirm:$false

Get-NsxIpSet IP-LogInsight-VIP | Remove-NsxIpSet -confirm:$false

Get-NsxService | ? {$_.name -notmatch ("DHCP") -AND $_.name -notmatch ("IPv6")} | Remove-NsxService -confirm:$false

Get-VM mgt-loginsight01 | Stop-VM -confirm:$false | Remove-Vm -deletepermanently -confirm:$false
Get-VM mgt-loginsight02 | Stop-VM -confirm:$false | Remove-Vm -deletepermanently -confirm:$false
Get-VM mgt-loginsight03 | Stop-VM -confirm:$false | Remove-Vm -deletepermanently -confirm:$false

write-host -ForegroundColor Green "Purge Complete"