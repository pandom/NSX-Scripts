$LiFileName = "VMware-vRealize-Log-Insight-4.5.0-5654101.ova"
#Connection details
$VIUserName = "administrator@vsphere.local"
$VIPassword = "VMware1!"

#OVF temp directory
$LiOvfLocation = "\\10.35.253.138\data01\Build\VMware\vRealize\Log Insight\$LiFileName"
#Common configuration
$NodeNetmask = "255.255.255.0"
$LiGateway = "192.168.110.1"
$LiDNSServer = "192.168.110.10"
$DomainName = "corp.local"
$RootPw = "VMware1!"
$ManagementNetwork = "VM Network"
$LiNodeSize = "xsmall"
#Node specific configuration
#Node1
$LiNode1HostName = "vrli-01a"
$LiNode1IpAddress = "192.168.110.198"

 # vSphere
 $clname = "Management & Edge Cluster"
 $dsname = "MgmtData"
 #OVA 
 $DiskFormat = "thin"

 #storage of OVA
 $storageuser = "cloud\nasguest"
 $storagepass = "P@ssw0rd"

 $controlcenter = "ControlCenter"

$ds = get-datastore $dsname
$cl = get-cluster $clname
$VMHost = $cl | Get-VMHost | Sort MemoryUsageGB | Select -first 1
$nw = $VmHost | Get-VirtualPortGroup -name $ManagementNetwork
 Write-Host -ForegroundColor Green "Deploying Log Insight node $LiNode1HostName"
 $ovfconfiguration = Get-OvfConfiguration -ovf $LiOvfLocation
 $ovfconfiguration.deploymentOption.value = $LiNodeSize
 $ovfconfiguration.ipAssignment.ipProtocol.value = "IPv4"
 $ovfconfiguration.NetworkMapping.Network_1.value = $nw.name
 $ovfconfiguration.vami.VMware_vCenter_Log_Insight.hostname.value = $LiNode1HostName
 $ovfconfiguration.vami.VMware_vCenter_Log_Insight.ip0.value = $LiNode1IpAddress
 $ovfconfiguration.vami.VMware_vCenter_Log_Insight.netmask0.value = $LiNodeNetmask
 $ovfconfiguration.vami.VMware_vCenter_Log_Insight.gateway.value = $LiGateway
 $ovfconfiguration.vami.VMware_vCenter_Log_Insight.DNS.value = $LiDNSServer
 $ovfconfiguration.vami.VMware_vCenter_Log_Insight.searchpath.value = $DomainName
 $ovfconfiguration.vami.VMware_vCenter_Log_Insight.domain.value = $DomainName
 $ovfconfiguration.vm.rootpw.value = $RootPw
 
 # Select host with lowest memory
 
 
 Import-vApp -Source $LiOvfLocation -OvfConfiguration $OvfConfiguration -Name $LiNode1Hostname -Location $cl -VMHost $Vmhost -Datastore $ds -DiskStorageFormat $DiskFormat | out-null
 

 ##VIDM
$vidmfilename = "identity-manager-3.0.0.0-6651498.ova"
$vidmovflocation = "\\10.35.253.138\data01\Build\VMware\Identity Manager\$vidmfilename"

$vidmhostname = "vidm-01a"
$vamitimezone = "Australia/Sydney"
$vidmIpAddress = "192.168.110.199"
$vidmgateway = "192.168.110.1"

$ovfconfiguration = Get-OvfConfiguration -ovf $vidmovflocation

$ovfconfiguration.Common.vami.hostname.value = $vidmhostname
$ovfconfiguration.Common.vamitimezone.value = $vamitimezone
$ovfconfiguration.ipAssignment.ipProtocol.value = "IPv4"
$ovfconfiguration.NetworkMapping.Network_1.value = $nw.name

$ovfconfiguration.vami.IdentityManager.ip0.value = $vidmIpAddress
$ovfconfiguration.vami.IdentityManager.netmask0.value = $NodeNetmask
$ovfconfiguration.vami.IdentityManager.DNS.value = $vidmdns
$ovfconfiguration.vami.IdentityManager.searchpath.value = $DomainName
$ovfconfiguration.vami.IdentityManager.domain.value = $DomainName
$ovfconfiguration.vami.IdentityManager.gateway.value = $vidmgateway

Import-vApp -Source $LiOvfLocation -OvfConfiguration $OvfConfiguration -Name $vidmhostname -Location $cl -VMHost $Vmhost -Datastore $ds -DiskStorageFormat $DiskFormat | out-null

# Start VMs
Get-Vm $vidmhostname | Start-Vm
Get-Vm $LiNode1HostName | Start-VM

