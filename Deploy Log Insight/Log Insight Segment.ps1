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
  $SecurityGroupAdminSourceName = "SG-Administrative-Sources"
  )

  write-host -ForegroundColor Green "

  Welcome to the Log Insight Segmentor tool

  _                   _____           _       _     _
  | |                 |_   _|         (_)     | |   | |
  | |     ___   __ _    | |  _ __  ___ _  __ _| |__ | |_
  | |    / _ \ / _` |   | | | '_ \/ __| |/ _` | '_ \| __|
  | |___| (_) | (_| |  _| |_| | | \__ \ | (_| | | | | |_
  |______\___/ \__, | |_____|_| |_|___/_|\__, |_| |_|\__|
               __/ |                     __/ |
              |___/                     |___/
   _____                                 _
  / ____|                               | |
  | (___  ___  __ _ _ __ ___   ___ _ __ | |_ ___  _ __
  \___ \ / _ \/ _` | '_ ` _ \ / _  \'_ \  __/ _ \| '__|
  ____) |  __/ (_| |  | | | | |  __/ | | | | (_) |  |
  |_____/ \___|\__, |_| |_| |_|\___|_| |_|\_\___/|_|
               __/ |
              |___/
  "
###########################
# Prompt user
write-warning "This script is design to be deployed against a multi-node Log Insight cluster where the Integrated Load Balancer (ILB) is configured. The firewall rules are built around this. The script currently is configured to use $LogInsightLoadBalancerIPAddress . Is this your ILB IP address? If not rerun this PowerShell script with -LogInsightLoadBalancerIPAddress <Your LI ILB IP Address>"

if ( (Read-Host "Is the printed LI ILB correct? (y) ?") -ne "y" ) { throw "User has cancelled the operation" }

write-warning "This script will create the required objects and Distributed Firewall rules to segment Log Insight. This will combine a number of predefined variables and used inputs to do this. An administrator will need to append Security Tag ST-LogInsight-Node to each Log Insight Virtual Machine for firewall rules to take effect."

if ( (Read-Host "Continue (y) ?") -ne "y" ) { throw "User has cancelled the operation" }

###################################
#Check we were called with required modules loaded...
import-module PowerNsx -DisableNameChecking
if ( -not (( Get-module PowerNsx ) -and ( Get-Module VMware.VimAutomation.Core ) )) { throw "Required modules not loaded.  PowerCLI v6, PowerNSX and Labs modules required."}
  else { write-host -ForegroundColor Green "PowerNsx and required PowerCLI modules installed"}


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
