## Deploy NSX-T Controller
#Environment
$clname = "Management"
$dsname = "STO-SRV-001"
$pgname = "PP-MGT-Guest"

$ovflocation = "\\10.35.253.138\data01\Build\VMware\NSX Transformers\2.0\nsx-controller-2.0.0.0.0.6080938.ova" ##vdr-mac
#$ovflocation = "\\10.35.253.138\data01\Build\VMware\NSX Transformers\2.0\nsx-controller-2.0.0.0.0.6058270.ova" pre-RTQA, Maclearning
#$ovflocation =  "\\10.35.253.138\data01\Build\VMware\NSX Transformers\1.10\nsx-controller-1.1.0.0.0.4788146.ova"

#Edge
$hn = "pp-mgt-nsxctrl01"
$ip = "192.168.254.11"
# $hn = "pp-mgt-nsxctrl02"
# $ip = "192.168.254.12"
# $hn = "pp-mgt-nsxctrl03"
# $ip = "192.168.254.13"
$gw = "192.168.254.1"
$sn = "255.255.255.128"
$dns = "192.168.254.7"
$ntp = "192.168.65.255,192.168.65.254"
$dm = "pp.sin.nicira.eng.vmware.com"


#OVF Details
$password = "VMware1!"
$df = "thin"

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