## Deploy NSX-T Edge
#Environment
$clname = "Management"
$dsname = "STO-SRV-001"
$pgname = "PP-MGT-Guest"
$teppgname = "PP-MGT-TEP"
$vlanpgname = "PP-MGT-Tenant-Interconnect"

$ovflocation = "\\10.35.253.138\data01\Build\VMware\NSX Transformers\2.0\nsx-edge-2.0.0.0.0.6080944.ova" #vdr-mac
# $ovflocation = "\\10.35.253.138\data01\Build\VMware\NSX Transformers\2.0\nsx-edge-2.0.0.0.0.6058279.ova" pre-RTQA, Maclearning
#$ovflocation =  "\\10.35.253.138\data01\Build\VMware\NSX Transformers\1.10\nsx-edge-1.1.0.0.0.4788148.ova"

#Edge
$hn = "pp-mgt-nsxedge01"
$ip = "192.168.254.31"
$hn = "pp-mgt-nsxedge02"
$ip = "192.168.254.32"
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