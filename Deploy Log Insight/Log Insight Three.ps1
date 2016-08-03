

## Deploy Log Insight 3.3.1.
#To-Do:	* Check for Thin Provision
#		* Add PowerLogInsight stuff in
param (
    $ClusterName = "Mgmt01",
    $DatastoreName = "MgmtData",
    $VdsName = "Mgt_int_vds",
    $VdPortGroupName = "Internal",
    ## OVA Global settings
    $LogInsightOvaLocation = "Z:\Lab\vrli.ova",
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
    $NtpServer = "$LogInsightDns",


    $vCenter = "vc-01a.corp.local",
    $vCenterUsername = "Administrator@vsphere.local",
    $vCenterPassword = "VMware1!",

    $LogInsightLicense = "PUT KEY HERE",

    $port = "443",

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


    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.value = $LogInsightServer1
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.value = $LogInsightIpAddress1
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.netmask0.value = $LogInsightNetmask
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.gateway.value = $LogInsightGateway
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.DNS.value = $LogInisghtDns
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.searchpath.value = $LogInsightSearchPath
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.domain.value = $LogInsightDomain
    $OvfConfiguration.vm.rootpw.value = $RootPw

    Import-vApp $LogInsightOvaLocation -OvfConfiguration $OvfConfiguration -name $LogInsightHostName1 -Location $Cluster -VMhost $Vmhost -Datastore $Datastore

    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.value = $LogInsightServer2
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.value = $LogInsightIpAddress2
    Import-vApp $LogInsightOvaLocation -OvfConfiguration $OvfConfiguration -name $LogInsightHostName2 -Location $Cluster -VMhost $Vmhost -Datastore $Datastore

    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.value = $LogInsightServer3
    $OvfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.value = $LogInsightIpAddress3
    Import-vApp $LogInsightOvaLocation -OvfConfiguration $OvfConfiguration -name $LogInsightHostName3 -Location $Cluster -VMhost $Vmhost -Datastore $Datastore

    sleep 5
    $LI1 = get-vm $LogInsightHostName1
    $LI2 = get-vm $LogInsightHostName2
    $LI3 = get-vm $LogInsightHostName3
    ########
    # Start Virtual Machines
    $LI1 | start-vm
    sleep 5
    $LI2 | start-vm
    sleep 5
    $LI3 | start-vm
   
