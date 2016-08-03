
#Script
    param (
        ## Creating Log Insight buckets
        $LogInsightVmNames = "mgt-log*",
        $LogInsightTagName = "ST-Mgt-LogInsight",
        $LogInsightFirewallSectionName = "Mgt-LogInsight",
        #Security Group
        $LogInsightSecurityGroupName = "SG-Mgt-LogInsight-Cluster",
        $LogInsightOuterSecurityGroupName = "SG-Mgt-LogInsight-Outer",
        #Initial rules whilst learning
        $FirewallRuleClusterLearnName = "FW-Mgt-LogInsight-Cluster-Learn",
        $FirewallRuleExternalLearnName = "FW-Mgt-LogInsight-External-Learn",
        $FirewallRuleCatchLearnName = "FW-Mgt-LogInsight-Catch-Learn",
        #Final Rules when called
        $FirewallRuleClusterName = "FW-Mgt-LogInsight-Cluster",
        $FirewallRuleExternalName = "FW-Mgt-LogInsight-External",
        $FirewallRuleManagementName = "FW-Mgt-LogInsight-Management",
        $FirewallRuleCatchName = "FW-Mgt-LogInsight-Catch",
        #Distributed Firewall Tags
        $LogInsightClusterDfwTagName = "LogInsightCluster",
        $LogInsightExternalDfwTagName = "LogInsightExternal",
        $LogInsightOuterDfwTagName = "LogInsightCatch",
        #New Services
        $ServiceLogInsightClusterName = "SV-LogInsight-Cluster",
        
        $ManagementClusterName = "SG-Management-Cluster"
        $LogInsightVipName = "IP-Mgt-LogInsight-VIP",
        $LogInsightVipIp = "10.35.254.8",
        $ManagementHostsIp = "10.35.252.192/26",
        $ComputeHostsIp = "10.35.253.192/26",
        $ComputeHostsName = "IP-Compute-Hosts",
        $ManagementHostsName = "IP-Management-Hosts",
        $pfSenseIp = "10.35.254.6",
        $pfSenseName = "IP-Mgt-pfSense",
        $MgtJumpName = "mgt-tempjump",
        $NsxManagerIp = "10.35.254.39",
        $NsxManagerName = "IP-Mgt-NsxVMgr01",


        #Management Access
        $tcp80 = (New-NsxService -name "tcp/80" -protocol "tcp" -port "80"),
        $tcp443 = (New-NsxService -name "tcp/443" -protocol "tcp" -port "443"),
        $tcp22 = (New-NsxService -name "tcp/22" -protocol "tcp" -port "22"),
        #Sending sources
        $tcp514 =  (New-NsxService -name "tcp/514" -protocol "tcp" -port "514"),
        $udp514 =  (New-NsxService -name "udp/514" -protocol "udp" -port "514"),
        $tcp1514 = (New-NsxService -name "tcp/1515" -protocol "tcp" -port "1514"),
        $tcp9000 = (New-NsxService -name "tcp/9000" -protocol tcp -port "9000"),
        $tcp9543 = (New-NsxService -name "tcp/9543" -protocol "tcp" -port "9543"),
        #Cluster comms
        $tcp7000 = (New-NsxService -name "tcp/7000" -protocol "tcp" -port "7000"),
        $tcp9042 = (New-NsxService -name "tcp/9042" -protocol "tcp" -port "9042"),
        $tcp9160 = (New-NsxService -name "tcp/9160" -protocol "tcp" -port "9160"),
        $tcp59778 = (New-NsxService -name "tcp/59778" -protocol "tcp" -port "59778"),
        $tcp16520range = (New-NsxService -name "tcp/16520-80" -protocol "tcp" -port 16520-16580),
        #Food and Water
        $udp123 = (New-NsxService -name "udp/123" -protocol "udp" -port "123"),
        $tcp25 = (New-NsxService -name "tcp/25" -protocol "tcp" -port "25"),
        $tcp465 = (New-NsxService -name "tcp/465" -protocol "tcp" -port "465"),
        $tcp53 = (New-NsxService -name "tcp/53" -protocol "tcp" -port "53"),
        $udp53 = (New-NsxService -name "udp/53" -protocol "udp" -port "53"),
        $tcp389 = (New-NsxService -name "tcp/389" -protocol "tcp" -port "389"),
        $udp389 = (New-NsxService -name "udp/389" -protocol "udp" -port "389"),
        $tcp636 = (New-NsxService -name "tcp/636" -protocol "tcp" -port "636"),
        $tcp3268 = (New-NsxService -name "tcp/3268" -protocol "tcp" -port "3268"),
        $tcp3269 = (New-NsxService -name "tcp/3269" -protocol "tcp" -port "3269"),
        $tcp88 = (New-NsxService -name "tcp/88" -protocol "tcp" -port "88"),
        $udp88 = (New-NsxService -name "udp/88" -protocol "udp" -port "88")   
        

    )


$ntp1 = "192.168.65.254"
$ntp2 = "192.168.65.255"
$ntpname = "IP-Mgt-NTP"


$dns1 = "mgt-dns01"
$dns2 = "mgt-dns02"
$dns = (Get-VM $dns1,$dns2) 
$DnsSecurityGroupName = "SG-Mgt-Dns"
$DnsSecurityGroup = "SG-Mgt-Dns"
$dc1 = "mgt-dc01"
$dc2 = "mgt-dc02"
$dcs = (Get-VM $dc1,$dc2)
$AdSecurityGroupName = "SG-Mgt-Active-Directory"

$vc1 = (Get-Vm mgt-vcenter01)
$vc2 = (Get-Vm comp-vcenter01)
$IpSetNTP = New-NsxIpSet -name $NtpName -IpAddresses "$ntp1,$ntp2"

$AdSecurityGroup = New-NsxSecurityGroup -name $AdSecurityGroupName -includeMember (get-vm $dc1,$dc2)
$DnsSecurityGroup = New-NsxSecurityGroup -name $DnsSecurityGroupName -includeMember (get-vm $dns1,$dns2)


#Create Security Tag, attach security tag to selected Virtual Machines, Create security group with given Security Tag as membership and then create out Security Group
    $LogInsightTag = New-NsxSecurityTag $LogInsightTagName
    $LogInsightVm = get-vm $LogInsightVmNames
    $LogInsightVm | New-NsxSecurityTagAssignment -ApplyTag -SecurityTag $LogInsightTag
    $LogInsightClusterSecurityGroup = New-NsxSecurityGroup $LogInsightSecurityGroupName -IncludeMember $LogInsightTag
    $LogInsightOuterSecurityGroup = New-NsxSecurityGroup $LogInsightOuterSecurityGroupName -IncludeMember $LogInsightClusterSecurityGroup


## Creating DFW Section for Log Insight
$LogInsightFirewallSection = New-NsxFirewallSection $LogInsightFirewallSectionName

##Cluster Rules
Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleClusterLearnName -source $LogInsightClusterSecurityGroup -Destination $LogInsightClusterSecurityGroup -enableLogging -action "allow" -AppliedTo $LogInsightClusterSecurityGroup -tag $LogInsightClusterDfwTagName -position top
##External Rules
Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleExternalLearnName -enableLogging -action "allow" -AppliedTo $LogInsightClusterSecurityGroup -tag $LogInsightExternalDfwTagName -position bottom
##Catch all
Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleCatchLearnName -enableLogging -action "allow" -AppliedTo $LogInsightOuterSecurityGroup -tag $LogInsightCatchDfwTagName -position bottom


##

#Cluster Rules

Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleClusterName -Source (Get-NsxSecurityGroup $LogInsightSecurityGroupName) -Destination(Get-NsxSecurityGroup $LogInsightSecurityGroupName) -service $tcp7000,$tcp9042,$tcp9160,$tcp59778,$tcp16520range,$tcp80,$tcp443,$tcp22,$tcp514,$udp514,$tcp1514,$tcp9000,$tcp9543  -Action "Allow" -position top -AppliedTo (Get-NsxSecurityGroup $LogInsightSecurityGroupName)


## Creating a Security Group for sources



$ManagementCluster = Get-Cluster
$ManagementClusterSG = New-NsxSecurityGroup  $ManagementClusterName -includeMember $ManagementCluster
$IpSetComputeHosts = New-NsxIpSet -name $ManagementHostsName -IpAddresses $ManagementHostsIp
$IpSetManagementHosts = New-NsxIpSet -name $ComputeHostsName -IpAddresses $ComputeHostsIp  
$IpSetLogInsightVip = New-NsxIpSet -name $LogInsightVipName -IpAddresses $LogInsightVipIp
$IpSetpfSenseIP = New-NsxIpSet -name $pfSenseName -IpAddresses $pfSenseIp
$IpSetNsxvMgr   = New-NsxIpSet -name $NsxManagerName -IpAddresses $NsxManagerIp 
$mgtjump = Get-Vm $mgtjumpname
## Create a FW rule for Virtual Sources

Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleExternalName -Source $ManagementClusterSG, $IpSetComputeHosts, $IpSetManagementHosts, $IpSetNsxvMgr -Destination $IpSetLogInsightVip -service $tcp514,$udp514,$tcp1514,$tcp9000,$tcp9543 -Action "Allow" -position top -AppliedTo (Get-NsxSecurityGroup $LogInsightSecurityGroupName)


## Create a FW rule for Management Sources

Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleManagementName -Source $IpSetpfSenseIP,$mgtjump -Destination $IpSetLogInsightVip -service $tcp80, $tcp443, $tcp22 -Action "Allow" -position top -AppliedTo (Get-NsxSecurityGroup $LogInsightSecurityGroupName)




Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleManagementName -Source (Get-NsxSecurityGroup $LogInsightSecurityGroupName) -Destination $AdSecurityGroup -service $tcp88,$udp88,$tcp389,$udp389 -Action "Allow" -position top -AppliedTo (Get-NsxSecurityGroup $LogInsightSecurityGroupName)

Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleManagementName -Source (Get-NsxSecurityGroup $LogInsightSecurityGroupName) -Destination $DnsSecurityGroup -service $udp53,$tcp53 -Action "Allow" -position top -AppliedTo (Get-NsxSecurityGroup $LogInsightSecurityGroupName)

Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleManagementName -Source (Get-NsxSecurityGroup $LogInsightSecurityGroupName) -Destination $IpSetNTP -service $udp123 -Action "Allow" -position top -AppliedTo (Get-NsxSecurityGroup $LogInsightSecurityGroupName)



Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name $FirewallRuleManagementName -Source (Get-NsxSecurityGroup $LogInsightSecurityGroupName) -Destination $vc1,$vc2 -service $tcp443 -Action "Allow" -position top -AppliedTo (Get-NsxSecurityGroup $LogInsightSecurityGroupName)

#ViewDesktops
#


#Purge all rules except ones used by Default Rule.
#Get-NsxService | ? {$_.name -notmatch ("DHCP") -AND $_.name -notmatch ("IPv6")} | Remove-NsxService -confirm:$false








#Get-NsxService | ? {$_.name -notmatch ("DHCP") -AND $_.name -notmatch ("IPv6")} | Remove-NsxService -confirm:$false

# $SGWeb = New-NsxSecurityGroup "SG-Web"
# $SGApp = New-NsxSecurityGroup "SG-App"
# $SGDb = New-NsxSecurityGroup "SG-Db"
# $SGBookstore = New-NsxSecurityGroup "SG-Bookstore" -includeMember ($SGApp,$SGWeb,$SGDb)

# New-NsxFirewallSection "Bookstore Application"
# Get-NsxFirewallSection "Bookstore Application" | New-NsxFirewallRule -name "Bookstore Web Learn" -enableLogging -action "Allow" -tag "Bookstore-Web" -AppliedTo $SGWeb
# Get-NsxFirewallSection "Bookstore Application" | New-NsxFirewallRule -name "Bookstore App Learn" -enableLogging -action "Allow" -tag "Bookstore-App" -AppliedTo $SGApp
# Get-NsxFirewallSection "Bookstore Application" | New-NsxFirewallRule -name "Bookstore Db Learn" -enableLogging -action "Allow" -tag "Bookstore-Db" -AppliedTo $SGDb
# Get-NsxFirewallSection "Bookstore Application" | New-NsxFirewallRule -name "Bookstore Catch" -enableLogging -action "Allow" -tag "Bookstore-Catch" -AppliedTo $SGBookstore -position bottom


