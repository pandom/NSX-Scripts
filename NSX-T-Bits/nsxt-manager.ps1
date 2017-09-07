## Deploy NSX-T Manager
#Environment
$clname = "Management"
$dsname = "STO-SRV-001"
$pgname = "PP-MGT-Guest"

$ovflocation = "\\10.35.253.138\data01\Build\VMware\NSX Transformers\2.0\nsx-manager-2.0.0.0.0.6080942.ova" ##vdr-mac


#Edge
$hn = "pp-mgt-nsxmgr01"
$ip = "192.168.254.19"
# $hn = "pp-mgt-nsxmgr02"
# $ip = "192.168.254.20"
# $hn = "pp-mgt-nsxmgr03"
# $ip = "192.168.254.21"
$gw = "192.168.254.1"
$sn = "255.255.255.128"
$dns = "192.168.254.7"
$ntp = "192.168.65.255,192.168.65.254"
$dm = "pp.sin.nicira.eng.vmware.com"


#OVF Details
$password = "VMware1!"
$audituser = "audit"
$auditpass = "$password"
$cliuser = "admin"
$df = "thin"

# Deploy

$cl = get-cluster $clname
$vh = $cl | Get-VMHost | Sort MemoryUsageGB | Select -first 1
$ds = get-datastore $dsname
$nw = get-vdportgroup $pgname

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