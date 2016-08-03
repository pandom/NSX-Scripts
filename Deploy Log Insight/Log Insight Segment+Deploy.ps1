# Log Insight Segmentation Tool v0.1
# a: Anthony Burke
# b: networkinferno.net
# t: pandom_
#


  param (

#########################
# Default Ports for Log Insight

  $http = "80",
  $https = "443",
  $ssh = "22",
  #Sending sources
  $syslog =  "514",
  $secureSyslog = "1514",
  $agent = "9000",
  $secureAgent = "9543",
  #Cluster comms
  $Cassandra = "7000",
  $CassandraNPC = "9042",
  $ThriftClient = "9160",
  $ThriftServer = "59778",
  #Food and Water
  $Ntp = "123",
  #SMTP
  $SMTP = "25",
  $SMTPS = "465",
  #DNS
  $DNS = "53",
  #Active Directory
  $AD = "389",
  $ADssl = "636",
  $ADLogServer = "3268",
  $ADGlobalCatalog = "3269",
  $Kerberos = "88",
##############
# Mandatory LB IP definition
  $LogInsightLoadBalancerIPAddress = "192.168.100.95",
##############
# Firewall Rule addendum
  $LogInsightFirewallSectionName = "Log Insight Cluster",
  $LogInsightSecurityTagName = "ST-LogInsight-Node",
  $FirewallRuleClusterName = "FW-LogInsight-Cluster",
  $FirewallRuleManagementName = "FW-LogInsight-Management",
  $FirewallRuleExternalName = "FW-LogInsight-External",
  $LogInsightIlbName = "IP-LogInsight-VIP",
  $DenyTag = "LogInsight-Deny",
##############
# User-defined parameter
  $LogInsightSecurityGroupName = "SG-LogInsight-Cluster",
  $SecurityGroupAdName = "SG-ActiveDirectory",
  $SecurityGroupDNSName = "SG-DNS",
  $SecurityGroupSMTPName = "SG-SMTP",
  $SecurityGroupNTPName = "SG-NTP",
  $SecurityGroupvCenterName = "SG-vCenter",
  $SecurityGroupAdminSourceName = "SG-Administrative-Sources",
  #############
  # Deploying Log Insight Nodes
  $ClusterName = "Mgmt01",
  $DatastoreName = "MgmtData",
  $VdsName = "Mgt_int_vds",
  $VdPortGroupName = "Internal",
  ## OVA Global settings
  $LogInsightOvaLocation = "Z:\Lab\Li.ova",
  $IpProtocol = "IPv4",


  ## Log Insight OVA Settings
  $LogInsightApplianceSize = "xsmall",
  $LogInsightPortGroupName = "$VdPortGroupName",

  $LogInsightHostName1 = "mgt-loginsight01",
  $LogInsightIpAddress1 = "192.168.100.96",
  $LogInsightHostName2 = "mgt-loginsight02",
  $LogInsightIpAddress2 = "192.168.100.97",
  $LogInsightHostName3 = "mgt-loginsight03",
  $LogInsightIpAddress3 = "192.168.100.98",
  $LogInsightNetmask = "255.255.255.0",
  $LogInsightGateway = "192.168.100.1",
  $LogInisghtDns = "192.168.100.10",
  $LogInsightSearchPath = "corp.local",
  $LogInsightDomain = "corp.local",
  $RootPw = "VMware1!VMware1!",


  ## Log Insight Configuration Settings

  $AdminEmail = "admin@vmware.com",
  $LogInsightPassword = "VMware1!",
  $LogInsightEmail = "loginsight@corp.local",
  $SmtpServer = "192.168.100.15",
  $SmtpPort = "8080",
  $NtpServer = "192.168.100.10",


  $vCenter = "vc-01a.corp.local",
  $vCenterUsername = "Administrator@vsphere.local",
  $vCenterPassword = "VMware1!",

  $LogInsightLicense = "PUT KEY HERE",

  $port = "443"

  )


## DO NOT EDIT BELOW HERE ##

  write-host -ForegroundColor Green "

  Welcome to the Log Insight Deploy and Segment tool

  _                   _____           _       _     _   
 | |                 |_   _|         (_)     | |   | |  
 | |     ___   __ _    | |  _ __  ___ _  __ _| |__ | |_ 
 | |    / _ \ / _` |   | | | '_ \/ __| |/ _` | '_ \| __|
 | |___| (_) | (_| |  _| |_| | | \__ \ | (_| | | | | |_ 
 |______\___/ \__, |_|_____|_| |_|___/_|\__, |_| |_|\__|
 |  __ \       __/ | |                _  __/ |          
 | |  | | ___ |___/| | ___  _   _   _| ||___/           
 | |  | |/ _ \ '_ \| |/ _ \| | | | |_   _|              
 | |__| |  __/ |_) | | (_) | |_| |   |_|                
 |_____/ \___| .__/|_|\___/ \__, |       _              
  / ____|    | |             __/ |      | |             
 | (___   ___|_|_ _ _ __ ___|___/_ _ __ | |_            
  \___ \ / _ \/ _` | '_ ` _ \ / _ \ '_ \| __|           
  ____) |  __/ (_| | | | | | |  __/ | | | |_            
 |_____/ \___|\__, |_| |_| |_|\___|_| |_|\__|           
               __/ |                                    
              |___/                                     
  "
###########################
# Prompt user
write-warning "This script is design to be deployed against a multi-node Log Insight cluster where the Integrated Load Balancer (ILB) is configured. The firewall rules are built around this. The script currently is configured to use $LogInsightLoadBalancerIPAddress . Is this your ILB IP address? If not rerun this PowerShell script with -LogInsightLoadBalancerIPAddress <Your LI ILB IP Address>"

if ( (Read-Host "Is the printed LI ILB correct? (y) ?") -ne "y" ) { throw "User has cancelled the operation" }

write-warning "This script will create the required objects and Distributed Firewall rules to segment Log Insight. This will combine a number of predefined variables and used inputs to do this. An administrator will need to append add the management or adminsitraive source networks to Security Group $SecurityGroupAdminSourceName before Log Insight is accessed."

if ( (Read-Host "Continue (y) ?") -ne "y" ) { throw "User has cancelled the operation" }

###################################
#Check we were called with required modules loaded...
import-module PowerNsx -DisableNameChecking
if ( -not (( Get-module PowerNsx ) -and ( Get-Module VMware.VimAutomation.Core ) )) { throw "Required modules not loaded.  PowerCLI v6, PowerNSX and Labs modules required."}
  else { write-host -ForegroundColor Green "PowerNsx and required PowerCLI modules installed"}

###################################
#Checking parameters on the OVF

    $Cluster = (Get-Cluster $ClusterName)
    $Datastore = (Get-Datastore $DatastoreName)
    $PortGroup = (Get-Vdswitch $vdsname | Get-Vdportgroup $LogInsightPortGroupName)

    $VMHost = $Cluster| Get-VMHost | Sort MemoryUsageGB | Select -first 1
    
    $OvfConfiguration = Get-OvfConfiguration $LogInsightOvaLocation
    $OvfConfiguration.IpAssignment.IpProtocol.value = $IpProtocol
    $OvfConfiguration.DeploymentOption.value = $LogInsightApplianceSize
    $OvfConfiguration.NetworkMapping.Network_1.value = $PortGroup


    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.value = $LogInsightServer1
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.value = $LogInsightIpAddress1
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.netmask0.value = $LogInsightNetmask
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.gateway.value = $LogInsightGateway
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.DNS.value = $LogInisghtDns
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.searchpath.value = $LogInsightSearchPath
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.domain.value = $LogInsightDomain
    $OvfConfiguration.vm.rootpw.value = $RootPw
    write-host -ForegroundColor Green "$LogInsightHostName1 is being deployed on $VMHost"
    Import-vApp $LogInsightOvaLocation -OvfConfiguration $OvfConfiguration -name $LogInsightHostName1 -Location $Cluster -VMhost $Vmhost -Datastore $Datastore | out-null

    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.value = $LogInsightServer2
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.value = $LogInsightIpAddress2
    $VMHost = $Cluster| Get-VMHost | Sort MemoryUsageGB | Select -first 1
    write-host -ForegroundColor Green "$LogInsightHostName2 is being deployed on $VMHost"
    Import-vApp $LogInsightOvaLocation -OvfConfiguration $OvfConfiguration -name $LogInsightHostName2 -Location $Cluster -VMhost $Vmhost -Datastore $Datastore | out-null

    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.value = $LogInsightServer3
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.value = $LogInsightIpAddress3
    $VMHost = $Cluster| Get-VMHost | Sort MemoryUsageGB | Select -first 1
    write-host -ForegroundColor Green "$LogInsightHostName3 is being deployed on $VMHost"
    Import-vApp $LogInsightOvaLocation -OvfConfiguration $OvfConfiguration -name $LogInsightHostName3 -Location $Cluster -VMhost $Vmhost -Datastore $Datastore | out-null

    sleep 5
    $LI1 = get-vm $LogInsightHostName1
    $LI2 = get-vm $LogInsightHostName2
    $LI3 = get-vm $LogInsightHostName3
    write-host -ForegroundColor Green "$LogInsightHostName1, $LogInsightHostName2, and $LogInsightHostName3 are starting"
    $LI1 | start-vm | out-null
    sleep 5
    $LI2 | start-vm | out-null
    sleep 5
    $LI3 | start-vm | out-null
    write-host -ForegroundColor Green "Log Insight clusters have started. Beginning segmentation"

############################
# Creating Services
#
write-host -ForegroundColor Green "Creating the required Services"
  $u = "udp"
  $t = "tcp"
  #Management Access (HTTP/HTTPS/SSH)
  $t80 = (New-NsxService -name "$t/$http" -protocol "$t" -port "$Http")
  $t443 = (New-NsxService -name "$t/$https" -protocol "$t" -port "$Https")
  $t22 = (New-NsxService -name "$t/$ssh" -protocol "$t" -port "$Ssh")
  #Sending sources (Syslog, Agents, API)
  $t514 =  (New-NsxService -name "$t/$syslog" -protocol "$t" -port "$Syslog")
  $u514 =  (New-NsxService -name "$u/$Syslog" -protocol "$u" -port "$Syslog")
  $t1514 = (New-NsxService -name "$t/$SecureSyslog" -protocol "$t" -port "$secureSyslog")
  $t9000 = (New-NsxService -name "$t/$Agent" -protocol $t -port "$Agent")
  $t9543 = (New-NsxService -name "$t/$secureAgent" -protocol "$t" -port "$secureAgent")
  #Cluster comms (Cassandra and Thrift)
  $t7000 = (New-NsxService -name "$t/$Cassandra" -protocol "$t" -port "7000")
  $t9042 = (New-NsxService -name "$t/$CassandraNPC" -protocol "$t" -port "$CassandraNPC")
  $t9160 = (New-NsxService -name "$t/$ThriftClient" -protocol "$t" -port "$ThriftClient")
  $t59778 = (New-NsxService -name "$t/$ThriftServer" -protocol "$t" -port "$ThriftServer")
  $t16520range = (New-NsxService -name "$t/16520-80" -protocol "$t" -port 16520-16580)
  #Food and Water Services (AD/DNS/NTP/SMTP)
  $u123 = (New-NsxService -name "$u/$ntp" -protocol "$u" -port "$ntp")
  ##SMTP
  $t25 = (New-NsxService -name "$t/$smtp" -protocol "$t" -port "$Smtp")
  $t465 = (New-NsxService -name "$t/$SmtpS" -protocol "$t" -port "$SmtpS")
  ##DNS
  $t53 = (New-NsxService -name "$t/$dns" -protocol "$t" -port "$Dns")
  $u53 = (New-NsxService -name "$u/$dns" -protocol "$u" -port "$Dns")
  ##Active Directory
  $t389 = (New-NsxService -name "$t/$Ad" -protocol "$t" -port "$Ad")
  $u389 = (New-NsxService -name "$u/$Ad" -protocol "$u" -port "$Ad")
  $t636 = (New-NsxService -name "$t/$Adssl" -protocol "$t" -port "$Adssl")
  $t3268 = (New-NsxService -name "$t/$AdLogServer" -protocol "$t" -port "$AdLogServer")
  $t3269 = (New-NsxService -name "$t/$ADGlobalCatalog" -protocol "$t" -port "$ADGlobalCatalog")
  $t88 = (New-NsxService -name "$t/$Kerberos" -protocol "$t" -port "$Kerberos")
  $u88 = (New-NsxService -name "$u/$Kerberos" -protocol "$u" -port "$Kerberos")

############################
# Creating new Security Objects
  write-host -ForegroundColor Green "Creating Log Insight Security Tag $LogInsightSecurityTagName"
  # Create the Security Tag
  $LogInsightTag = New-NsxSecurityTag -name $LogInsightSecurityTagName
  # Create the cluster Security Group
  write-host -ForegroundColor Green "Creating Log Insight Security Group $LogInsightSecurityGroupName"
  $LogInsightSGCluster = New-NsxSecurityGroup $LogInsightSecurityGroupName -includeMember $LogInsightTag
  # Append Security Tag to deployed Log Insight Virtual Machines
  Get-VM $LI1,$LI2,$LI3 | New-NsxSecurityTagAssignment -ApplyTag $LogInsightTag
  # Place holder Security Groups for rules that allow definition instead of ANY
  # User to add objects to these security groups for Food and Water
  write-host -ForegroundColor Green "Creating Log Insight Security Group $SecurityGroupAdName"
  $SecurityGroupAd = New-NsxSecurityGroup $SecurityGroupAdName
  write-host -ForegroundColor Green "Creating Log Insight Security Group $SecurityGroupDNSName"
  $SecurityGroupDNS = New-NsxSecurityGroup $SecurityGroupDNSName
  write-host -ForegroundColor Green "Creating Log Insight Security Group $SecurityGroupSMTPName"
  $SecurityGroupSMTP = New-NsxSecurityGroup $SecurityGroupSMTPName
  write-host -ForegroundColor Green "Creating Log Insight Security Group $SecurityGroupNTPName"
  $SecurityGroupNTP = New-NsxSecurityGroup $SecurityGroupNTPName
  write-host -ForegroundColor Green "Creating Log Insight Security Group $SecurityGroupvCenterName"
  $SecurityGroupvCenter = New-NsxSecurityGroup $SecurityGroupvCenterName
  write-Host -ForegroundColor Green "Creating Log Insight Security Group $SecurityGroupAdminSourceName"
  $SecurityGroupAdminSource = New-NsxSecurityGroup $SecurityGroupAdminSourceName
  # Create the Log Insight IP Set for ILB
  write-host -ForegroundColor Green "Creating IP Set for Log Insight Load Balancer VIP"
  $LogInsightIlbIpSet = New-NsxIpSet -name $LogInsightIlbName -IpAddresses "$LogInsightLoadBalancerIPAddress"

############################
# Creating new firewall section
  write-host -ForegroundColor Green "Creating Log Insight Firewall Section"
  $LogInsightFirewallSection = New-NsxFirewallSection $LogInsightFirewallSectionName


############################
# Creating Cluster Rules
  write-host -ForegroundColor Green "Creating Log Insight Cluster Rules"
  Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name "$FirewallRuleClusterName Cluster Replication" -Source $LogInsightSGCluster -Destination $LogInsightSGCluster -service $t7000,$t9042,$t9160,$t59778,$t16520range,$t80,$t443,$t22,$t514,$u514,$t1514,$t9000,$t9543  -Action "Allow" -position top -AppliedTo $LogInsightSGCluster | out-null


############################
# Creating External Sources Rule
  write-host -ForegroundColor Green "Creating Log Insight External Source Rules"
  Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -name "$FirewallRuleExternalName Syslog/API"  -Destination $LogInsightIlbIpSet -service $t514,$u514,$t1514,$t9000,$t9543 -Action "Allow" -position top -AppliedTo $LogInsightSGCluster | out-null

############################
# Creating Management Rules
  write-host -ForegroundColor Green "Creating Log Insight Management Rules"
  Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -Name "$FirewallRuleManagementName Admin Access" -Source $SecurityGroupAdminSource -Destination $LogInsightIlbIpSet -service $t80,$t443,$t22 -action "Allow" -position top -AppliedTo $LogInsightSGCluster | out-null

############################
# Food and Water
  write-host -ForegroundColor Green "Creating Log Insight Food and Water Rules for Active Directory"
  Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -Name "$FirewallRuleManagementName AD" -Source $LogInsightSGCluster -Destination $SecurityGroupAd -service $t389,$u389,$t636,$t3268,$t3269,$t88,$u88 -Action "Allow" -position top -AppliedTo $LogInsightSGCluster | out-null
  write-host -ForegroundColor Green "Creating Log Insight Food and Water Rules for DNS"
  Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -Name "$FirewallRuleManagementName DNS" -Source $LogInsightSGCluster -Destination $SecurityGroupDNS -service $t53,$u53 -Action "Allow" -position top -AppliedTo $LogInsightSGCluster | out-null
  write-host -ForegroundColor Green "Creating Log Insight Food and Water Rules for SMTP"
  Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -Name "$FirewallRuleManagementName SMTP" -Source $LogInsightSGCluster -Destination $SecurityGroupSMTP -service $t25,$t465 -Action "Allow" -position top -AppliedTo $LogInsightSGCluster | out-null
  write-host -ForegroundColor Green "Creating Log Insight Food and Water Rules for NTP"
  Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -Name "$FirewallRuleManagementName NTP" -Source $LogInsightSGCluster -Destination $SecurityGroupNTP -service $u123 -Action "Allow" -position top -AppliedTo $LogInsightSGCluster | out-null
  write-host -ForegroundColor Green "Creating Log Insight Food and Water Rules for vCenter"
  Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -Name "$FirewallRuleManagementName vCenter" -Source $LogInsightSGCluster -Destination $SecurityGroupvCenter -service $t443 -Action "Allow" -position top -AppliedTo $LogInsightSGCluster | out-null
############################
# Application Microsegment
  write-host -ForegroundColor Green "Creating Log Insight Specific Deny rules"
  Get-NsxFirewallSection $LogInsightFirewallSectionName | New-NsxFirewallRule -Name "FW-LogInsight-Deny" -Action "Deny" -tag $denytag -position bottom -AppliedTo $LogInsightSGCluster | out-null

############################
# Application Microsegment
  write-host -ForegroundColor Green "Log Insight initial segmentation complete. Please add an object or IP Set to $SecurityGroupAdminSourceName to connect to Log Insight."

