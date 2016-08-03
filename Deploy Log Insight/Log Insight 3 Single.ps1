## Log Insight Parameters

## Cluster Settings

param (
$ClusterName = "Mgmt01",
    $DatastoreName = "NFS-DS-001",
    $VdsName = "mgt-vds01",
    $VdPortGroupName = "VLAN999-MGT-Guest",
    ## OVA Global settings
    $LogInsightOvaLocation = "Z:\Lab\vrli.ova",
    $IpProtocol = "IPv4",


    ## Log Insight OVA Settings
    $LogInsightApplianceSize = "medium",
    $LogInsightPortGroupName = "$VdPortGroupName",

    $LogInsightHostName1 = "mgt-loginsight01",
    $LogInsightIpAddress1 = "10.35.254.81",
    $LogInsightHostName2 = "mgt-loginsight02",
    $LogInsightIpAddress2 = "10.35.254.82",
    $LogInsightHostName3 = "mgt-loginsight03",
    $LogInsightIpAddress3 = "10.35.254.83",
    $LogInsightNetmask = "255.255.255.128",
    $LogInsightGateway = "10.35.254.1",
    $LogInsightDns = "10.35.254.4",
    $LogInsightSearchPath = "sin.nicira.eng.vmware.com",
    $LogInsightDomain = "sin.nicira.eng.vmware.com", 
    $RootPw = "VMware1!"

    )

## DO NOT EDIT BELOW HERE
$Cluster = (Get-Cluster $ClusterName)
$Datastore = (Get-Datastore $DatastoreName)
$PortGroup = (Get-Vdswitch $vdsname | Get-Vdportgroup $LogInsightPortGroupName)
$VMHost = $Cluster| Get-VMHost | Sort MemoryUsageGB | Select -first 1



$OvfConfiguration = Get-OvfConfiguration $LogInsightOvaLocation

$OvfConfiguration.IpAssignment.IpProtocol.value = $IpProtocol
$OvfConfiguration.DeploymentOption.value = $LogInsightApplianceSize

$OvfConfiguration.NetworkMapping.Network_1.value = $PortGroup


$OvfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.value = $LogInsightHostName1
$OvfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.value = $LogInsightIpAddress1
$OvfConfiguration.vami.VMware_vCenter_Log_Insight.netmask0.value = $LogInsightNetmask
$OvfConfiguration.vami.VMware_vCenter_Log_Insight.gateway.value = $LogInsightGateway
$OvfConfiguration.vami.VMware_vCenter_Log_Insight.DNS.value = $LogInsightDns
$OvfConfiguration.vami.VMware_vCenter_Log_Insight.searchpath.value = $LogInsightSearchPath
$OvfConfiguration.vami.VMware_vCenter_Log_Insight.domain.value = $LogInsightDomain
$OvfConfiguration.vm.rootpw.value = $RootPw

Import-vApp $LogInsightOvaLocation -OvfConfiguration $OvfConfiguration -name $LogInsightHostName1 -Location $Cluster -VMhost $Vmhost -Datastore $Datastore
get-vm $LogInsightHostName | start-vm


$OvfConfiguration = Get-OvfConfiguration $LogInsightOvaLocation



