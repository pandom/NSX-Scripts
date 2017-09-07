## Deploy NSX-T Controller
#Environment
$clname = "Management"
$dsname = "STO-SRV-001"
$pgname = "PP-MGT-Guest"

#RTQA63
$ovflocation = "\\10.35.253.138\data01\Build\VMware\NSX Transformers\2.0\nsx-controller-2.0.0.0.0.6217020.ova"

#Edge
$gw = "192.168.254.1"
$sn = "255.255.255.128"
$dns = "192.168.254.7"
$ntp = "192.168.65.255,192.168.65.254"
$dm = "pp.sin.nicira.eng.vmware.com"


#OVF Details
$password = "VMware1!"
$df = "thin"


# Creating #1
$hn = "pp-mgt-nsxctrl01"
$ip = "192.168.254.11"
$cl = get-cluster $clname
$vh = $cl | Get-VMHost | Sort MemoryUsageGB | Select -first 1
$ds = get-datastore $dsname
$nw = get-vdportgroup $pgname

##OVF Deployment
$ovf = Get-OvfConfiguration -ovf $ovflocation
$ovf.common.nsx_passwd_0.value = "$password"
$ovf.common.nsx_cli_passwd_0.value = "$password"
#$ovf.common.extraPara.value = ""
$ovf.common.nsx_hostname.value = "$hn"
$ovf.common.nsx_gateway_0.value = "$gw"
$ovf.common.nsx_ip_0.value = "$ip"
$ovf.common.nsx_netmask_0.value = "$sn"
$ovf.common.nsx_dns1_0.value = "$dns"
$ovf.common.nsx_domain_0.value = "$dm"
$ovf.common.nsx_ntp_0.value = "$ntp"
$ovf.common.nsx_isSSHEnabled.value = "True"
$ovf.common.nsx_allowSSHRootLogin.value = "False" 
$ovf.NetworkMapping.Network_1.Value = "$($nw.name)"
$ovf.IpAssignment.IpProtocol.value = "IPv4"

Import-vApp -Source $OvfLocation -OvfConfiguration $ovf -Name $hn -Location $cl -VMHost $vh -Datastore $ds -DiskStorageFormat $Df | out-null

# Creating #2
$hn = "pp-mgt-nsxctrl02"
$ip = "192.168.254.12"
$cl = get-cluster $clname
$vh = $cl | Get-VMHost | Sort MemoryUsageGB | Select -first 1
$ds = get-datastore $dsname
$nw = get-vdportgroup $pgname

##OVF Deployment
$ovf = Get-OvfConfiguration -ovf $ovflocation
$ovf.common.nsx_passwd_0.value = "$password"
$ovf.common.nsx_cli_passwd_0.value = "$password"
#$ovf.common.extraPara.value = ""
$ovf.common.nsx_hostname.value = "$hn"
$ovf.common.nsx_gateway_0.value = "$gw"
$ovf.common.nsx_ip_0.value = "$ip"
$ovf.common.nsx_netmask_0.value = "$sn"
$ovf.common.nsx_dns1_0.value = "$dns"
$ovf.common.nsx_domain_0.value = "$dm"
$ovf.common.nsx_ntp_0.value = "$ntp"
$ovf.common.nsx_isSSHEnabled.value = "True"
$ovf.common.nsx_allowSSHRootLogin.value = "False" 
$ovf.NetworkMapping.Network_1.Value = "$($nw.name)"
$ovf.IpAssignment.IpProtocol.value = "IPv4"

Import-vApp -Source $OvfLocation -OvfConfiguration $ovf -Name $hn -Location $cl -VMHost $vh -Datastore $ds -DiskStorageFormat $Df | out-null

#Creating #3
$hn = "pp-mgt-nsxctrl03"
$ip = "192.168.254.13"
$cl = get-cluster $clname
$vh = $cl | Get-VMHost | Sort MemoryUsageGB | Select -first 1
$ds = get-datastore $dsname
$nw = get-vdportgroup $pgname

##OVF Deployment
$ovf = Get-OvfConfiguration -ovf $ovflocation
$ovf.common.nsx_passwd_0.value = "$password"
$ovf.common.nsx_cli_passwd_0.value = "$password"
#$ovf.common.extraPara.value = ""
$ovf.common.nsx_hostname.value = "$hn"
$ovf.common.nsx_gateway_0.value = "$gw"
$ovf.common.nsx_ip_0.value = "$ip"
$ovf.common.nsx_netmask_0.value = "$sn"
$ovf.common.nsx_dns1_0.value = "$dns"
$ovf.common.nsx_domain_0.value = "$dm"
$ovf.common.nsx_ntp_0.value = "$ntp"
$ovf.common.nsx_isSSHEnabled.value = "True"
$ovf.common.nsx_allowSSHRootLogin.value = "False" 
$ovf.NetworkMapping.Network_1.Value = "$($nw.name)"
$ovf.IpAssignment.IpProtocol.value = "IPv4"

Import-vApp -Source $OvfLocation -OvfConfiguration $ovf -Name $hn -Location $cl -VMHost $vh -Datastore $ds -DiskStorageFormat $Df | out-null


#Creating #1
## Deploy NSX-T Manager
#Environment
$clname = "Management"
$dsname = "STO-SRV-001"
$pgname = "PP-MGT-Guest"

$ovflocation = "\\10.35.253.138\data01\Build\VMware\NSX Transformers\2.0\nsx-manager-2.0.0.0.0.6218290.ova" ##RTQA63

#Edge
$hn = "pp-mgt-nsxmgr01"
$ip = "192.168.254.19"
# $hn = "pp-mgt-nsxmgr02"
# $ip = "192.168.254.20"
# $hn = "pp-mgt-nsxmgr03"
# $ip = "192.168.254.21"

#OVF Details
$password = "VMware1!"
$audituser = "audit"
$auditpass = "$password"
$cliuser = "admin"
$df = "thin"

# Deploy

$vh = $cl | Get-VMHost | Sort MemoryUsageGB | Select -first 1

##OVF Deployment
$ovf = Get-OvfConfiguration -ovf $ovflocation
$ovf.common.nsx_passwd_0.value = "$password"
$ovf.common.nsx_cli_passwd_0.value = "$password"
$ovf.common.nsx_cli_username.value = "$cliuser"
$ovf.common.nsx_cli_audit_username.value = "$audituser"
$ovf.common.nsx_cli_audit_passwd_0.value = "$auditpass"
#$ovf.common.extraPara.value = ""
$ovf.common.nsx_hostname.value = "$hn"
$ovf.common.nsx_gateway_0.value = "$gw"
$ovf.common.nsx_ip_0.value = "$ip"
$ovf.common.nsx_netmask_0.value = "$sn"
$ovf.common.nsx_dns1_0.value = "$dns"
$ovf.common.nsx_domain_0.value = "$dm"
$ovf.common.nsx_ntp_0.value = "$ntp"
$ovf.common.nsx_isSSHEnabled.value = "True"
$ovf.common.nsx_allowSSHRootLogin.value = "True" 
$ovf.NetworkMapping.Network_1.Value = "$($nw.name)"
$ovf.IpAssignment.IpProtocol.value = "IPv4"

Import-vApp -Source $OvfLocation -OvfConfiguration $ovf -Name $hn -Location $cl -VMHost $vh -Datastore $ds -DiskStorageFormat $Df | out-null

## Deploy NSX-T Edge
#Environment
$clname = "Management"
$dsname = "STO-SRV-001"
$pgname = "PP-MGT-Guest"
$teppgname = "PP-MGT-TEP"
$vlanpgname = "PP-MGT-Tenant-Interconnect"

$ovflocation = "\\10.35.253.138\data01\Build\VMware\NSX Transformers\2.0\nsx-edge-2.0.0.0.0.6217019.ova" #RTQA63

#Edge
$gw = "192.168.254.1"
$sn = "255.255.255.128"
$dns = "192.168.254.7"
$ntp = "192.168.65.255,192.168.65.254"
$dm = "pp.sin.nicira.eng.vmware.com"
$es = "large"

#OVF Details
$password = "VMware1!"
$df = "thin"

$cl = get-cluster $clname
$vh = $cl | Get-VMHost | Sort MemoryUsageGB | Select -first 1
$ds = get-datastore $dsname
$nw1 = get-vdportgroup $pgname
$nw2 = get-vdportgroup $teppgname
$nw3 = get-vdportgroup $vlanpgname

##OVF Deployment

$hn = "pp-mgt-nsxedge01"
$ip = "192.168.254.31"

$ovf = Get-OvfConfiguration -ovf $ovflocation
$ovf.common.nsx_passwd_0.value = "$password"
$ovf.common.nsx_cli_passwd_0.value = "$password"
#$ovf.common.extraPara.value = ""
$ovf.common.nsx_hostname.value = "$hn"
$ovf.common.nsx_gateway_0.value = "$gw"
$ovf.common.nsx_ip_0.value = "$ip"
$ovf.common.nsx_netmask_0.value = "$sn"
$ovf.common.nsx_dns1_0.value = "$dns"
$ovf.common.nsx_domain_0.value = "$dm"
$ovf.common.nsx_ntp_0.value = "$ntp"
$ovf.common.nsx_isSSHEnabled.value = "True"
$ovf.common.nsx_allowSSHRootLogin.value = "False" 
$ovf.NetworkMapping.Network_0.Value = "$($nw1.name)"
$ovf.NetworkMapping.Network_1.Value = "$($nw2.name)"
$ovf.NetworkMapping.Network_2.Value = "$($nw3.name)"
#not used - assigning to PP-TENANT-INTERCONNECT
$ovf.NetworkMapping.Network_3.Value = "$($nw3.name)"
$ovf.IpAssignment.IpProtocol.value = "IPv4"
$ovf.DeploymentOption.value = "$es"

Import-vApp -Source $OvfLocation -OvfConfiguration $ovf -Name $hn -Location $cl -VMHost $vh -Datastore $ds -DiskStorageFormat $Df | out-null


#Edge 2
$hn = "pp-mgt-nsxedge02"
$ip = "192.168.254.32"

$ovf = Get-OvfConfiguration -ovf $ovflocation
$ovf.common.nsx_passwd_0.value = "$password"
$ovf.common.nsx_cli_passwd_0.value = "$password"
#$ovf.common.extraPara.value = ""
$ovf.common.nsx_hostname.value = "$hn"
$ovf.common.nsx_gateway_0.value = "$gw"
$ovf.common.nsx_ip_0.value = "$ip"
$ovf.common.nsx_netmask_0.value = "$sn"
$ovf.common.nsx_dns1_0.value = "$dns"
$ovf.common.nsx_domain_0.value = "$dm"
$ovf.common.nsx_ntp_0.value = "$ntp"
$ovf.common.nsx_isSSHEnabled.value = "True"
$ovf.common.nsx_allowSSHRootLogin.value = "False" 
$ovf.NetworkMapping.Network_0.Value = "$($nw1.name)"
$ovf.NetworkMapping.Network_1.Value = "$($nw2.name)"
$ovf.NetworkMapping.Network_2.Value = "$($nw3.name)"
#not used - assigning to PP-TENANT-INTERCONNECT
$ovf.NetworkMapping.Network_3.Value = "$($nw3.name)"
$ovf.IpAssignment.IpProtocol.value = "IPv4"
$ovf.DeploymentOption.value = "$es"

Import-vApp -Source $OvfLocation -OvfConfiguration $ovf -Name $hn -Location $cl -VMHost $vh -Datastore $ds -DiskStorageFormat $Df | out-null