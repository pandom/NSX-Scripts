###
## Demo for Damo
# By Burkey
#

##Credentials
$vcuser = "administrator@vsphere.local"
$nsxuser = "admin"
$password = "VMware1!"

## VC Objects

$clustername = "Compute"
$dsname = "CompData"
$vmname1 = "Test-VM-001"
$vmname2 = "Test-VM-002"


## NSX-T objects
$edgeClusterName = "edgecluster1"
$transportZoneName = "TZ"
$logicalRouterNameT0 = "Tier0_LR"
$firewallSectionName = "automation_section"
$firewallRuleName = "automation_rule"
$nsgroupname = "dynamic-ns"
$logicalRouterNameT1 = "Tier1_LR_automation"
$ls1name = "LS1_automation"
$ls2name = "LS2_automation"

## Hashtable for Tags

$DemoTags = @{}
$DemoTags.Add("scope", "production")
$DemoTags.Add("tag","web")

##################

###########
#Connection Management
write-host -foregroundcolor Green "Connecting to vCenter and NSX-T Manager"

$null = Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false  -confirm:$false -WarningAction "silentlycontinue" -ErrorAction Ignore
$null = Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false -WarningAction "silentlycontinue" -ErrorAction Ignore
Connect-NsxtServer -Server nsxmgr-01a.corp.local -User $nsxuser -Password $password -WarningAction "silentlycontinue" -ErrorAction Ignore | Out-Null
Connect-VIServer -Server vc-01a.corp.local -User $vcuser -Password $password -WarningAction "silentlycontinue" -ErrorAction Ignore | Out-Null



###########
#NSX-T Service Import
$serviceEdgeClusters = Get-NsxTService com.vmware.nsx.edge_clusters
$serviceLogicalPorts = Get-NsxtService com.vmware.nsx.logical_ports
$serviceLogicalSwitch = Get-NsxtService com.vmware.nsx.logical_switches
$serviceTransportZones = Get-NsxTService com.vmware.nsx.transport_zones
$serviceLogicalRouters = Get-NsxTService com.vmware.nsx.logical_routers
$serviceLogicalRouterPorts = Get-NsxTService com.vmware.nsx.logical_router_ports
$serviceLogicalRouterAdvertisements = Get-NsxTService com.vmware.nsx.logical_routers.routing.advertisement
$serviceNsGroup = Get-NsxtService com.vmware.nsx.ns_groups
$serviceFirewallSections = Get-NsxtService com.vmware.nsx.firewall.sections
$serviceFirewallSectionRules = Get-NsxTService com.vmware.nsx.firewall.sections.rules



###########
# Creating the Logical Topology
#Collect pre-req objectss
write-host -foregroundcolor Green "Collecting UUIDs for $transportZoneName, $edgeClusterName, and $logicalRouterNameT0 "
$transportZone = $serviceTransportZones.list().results | Where-Object {$_.display_name -eq $transportZoneName}
$edgeCluster = $serviceEdgeClusters.list().results | Where-Object {$_.display_name -eq $edgeClusterName}
$tier0Router = $serviceLogicalRouters.list().results | Where-Object {$_.display_name -eq $logicalRouterNameT0 }

#Create T1 router k8st1
write-host -foregroundcolor Green "Creating T1 router $logicalRouterNameT1"
$specLogicalRouterT1 = $serviceLogicalRouters.help.create.logical_router.Create()
$specLogicalRouterT1.display_name = $logicalRouterNameT1 
$specLogicalRouterT1.edge_cluster_id = $edgeCluster.id
$specLogicalRouterT1.router_type = "TIER1"
$t1router = $serviceLogicalRouters.create($specLogicalRouterT1)

# Create a logical switch for LS_1
write-host -foregroundcolor Green "Creating logical switch on $ls1name"
$specLogicalSwitch = $serviceLogicalSwitch.help.create.logical_switch.Create()
$specLogicalSwitch.display_name = $ls1name
$specLogicalSwitch.transport_zone_id = $transportZone.id
$specLogicalSwitch.admin_state = "UP"
$specLogicalSwitch.replication_mode = "MTEP"
$specLogicalSwitch.tags.Add($DemoTags) | Out-Null
$ls1 = $serviceLogicalSwitch.create($specLogicalSwitch)

# Create a logical switch for LS_2
write-host -foregroundcolor Green "Creating logical switch on $ls2name"
$specLogicalSwitch = $serviceLogicalSwitch.help.create.logical_switch.Create()
$specLogicalSwitch.display_name = $ls2name
$specLogicalSwitch.transport_zone_id = $transportZone.id
$specLogicalSwitch.admin_state = "UP"
$specLogicalSwitch.replication_mode = "MTEP"
$specLogicalSwitch.tags.Add($DemoTags)  | Out-Null
$ls2 = $serviceLogicalSwitch.create($specLogicalSwitch)

# Create a port on the logical switch pod_access
write-host -foregroundcolor Green "Creating logical port on $logicalRouterNameT1"
$specLogicalSwitchPort = $serviceLogicalPorts.help.create.logical_port.create()
$specLogicalSwitchPort.display_name = "LP-$ls1name"
$specLogicalSwitchPort.description = "Logical Port for $($logicalRouterNameT1)"
$specLogicalSwitchPort.admin_state = "UP"
$specLogicalSwitchPort.logical_switch_id = $ls1.id
$lsport1 = $serviceLogicalPorts.create($specLogicalSwitchPort)

# Create a router downlink port and connect it to the switchport above
write-host -foregroundcolor Green "Creating LIF on $($t1router.display_name) for $ls1name"
$specLogicalRouterDownlinkPort = $serviceLogicalRouterPorts.Help.create.logical_router_port.logical_router_down_link_port.Create()
$specLogicalRouterDownlinkPort.description = "Logical Router LIF for $ls1name"
$specLogicalRouterDownlinkPort.display_name = "LIF_$ls1name"
$specLogicalRouterDownlinkPort.linked_logical_switch_port_id = @{"target_id" = $lsport1.id }
$specLogicalRouterDownlinkPort.subnets.Add(@{"ip_addresses" = @("172.16.243.1"); "prefix_length" = "24"}) | Out-Null
$specLogicalRouterDownlinkPort.logical_router_id = $t1router.id
$t1routerRpls1 = $serviceLogicalRouterPorts.create($specLogicalRouterDownlinkPort)

# Create a port on the logical switch pod_access
write-host -foregroundcolor Green "Creating logical port on $logicalRouterNameT1"
$specLogicalSwitchPort = $serviceLogicalPorts.help.create.logical_port.create()
$specLogicalSwitchPort.display_name = "LP-$ls2name"
$specLogicalSwitchPort.description = "Logical Port for $($logicalRouterNameT1)"
$specLogicalSwitchPort.admin_state = "UP"
$specLogicalSwitchPort.logical_switch_id = $ls2.id
$lsport2 = $serviceLogicalPorts.create($specLogicalSwitchPort)

# Create a router downlink port and connect it to the switchport above
write-host -foregroundcolor Green "Creating LIF on $($t1router.display_name) for $ls2name"
$specLogicalRouterDownlinkPort = $serviceLogicalRouterPorts.Help.create.logical_router_port.logical_router_down_link_port.Create()
$specLogicalRouterDownlinkPort.description = "Logical Router LIF for $ls2name"
$specLogicalRouterDownlinkPort.display_name = "LIF_$ls2name"
$specLogicalRouterDownlinkPort.linked_logical_switch_port_id = @{"target_id" = $lsport2.id }
$specLogicalRouterDownlinkPort.subnets.Add(@{"ip_addresses" = @("172.16.244.1"); "prefix_length" = "24"}) | Out-Null
$specLogicalRouterDownlinkPort.logical_router_id = $t1router.id
$t1routerRpls2 = $serviceLogicalRouterPorts.create($specLogicalRouterDownlinkPort)


# Create linked Port on Tier 0 for tier1
write-host -foregroundcolor Green "Creating router port on $($t1router.display_name)"

$specLinkedRouterPortOnT0 = $serviceLogicalRouterPorts.help.create.logical_router_port.logical_router_link_port_on_TIE_r0.Create()
$specLinkedRouterPortOnT0.description = "Port on T0 Router for $($t1router.display_name) (ID: $($t1router.id))"
$specLinkedRouterPortOnT0.display_name = "LinkedPortOnT0_$($t1router.display_name)"
$specLinkedRouterPortOnT0.logical_router_id =  $tier0Router.id
$linkedRouterPortOnT0 = $serviceLogicalRouterPorts.create($specLinkedRouterPortOnT0)
write-host -foregroundcolor Green "Creating router port on $($tier0router.display_name)"
# Create linked port on Tier 1 for to T0
$specLinkedRouterPortOnT1 = $serviceLogicalRouterPorts.help.create.logical_router_port.logical_router_link_port_on_TIE_r1.Create()
$specLinkedRouterPortOnT1.description = "Port on T1 Router for $($tier0Router.display_name) (ID: $($tier0Router.id))"
$specLinkedRouterPortOnT1.display_name = "LinkedPortOnT1_$($tier0Router.display_name)"
$specLinkedRouterPortOnT1.logical_router_id = $t1Router.id
$specLinkedRouterPortOnT1.linked_logical_router_port_id = @{"target_id" = $linkedRouterPortOnT0.id}
$linkedRouterPortOnT1 = $serviceLogicalRouterPorts.create($specLinkedRouterPortOnT1)

#Redistribution
write-host -foregroundcolor Green "Advertising nsx_connected routes on $logicalRouterNameT1"
$logicalRouterAdvertisementConfig = $serviceLogicalRouterAdvertisements.get($t1router.id)
$logicalRouterAdvertisementConfig.enabled = $True
$logicalRouterAdvertisementConfig.advertise_nsx_connected_routes = $True
$logicalRouterAdvertisementConfig.advertise_lb_vip = $True
$serviceLogicalRouterAdvertisements.update($t1router.id, $logicalRouterAdvertisementConfig) | Out-Null


###########
#Create VM

write-host -foregroundcolor Green "Creating Shell VMs $vmname1 and $vmname2 "

$ds = Get-Datastore $dsname
$cl = Get-Cluster $clustername
$vmhost = $cl | get-vmhost | select -first 1
$folder = get-folder -type VM -name vm
$vmsplat = @{
    "VMHost" = $vmhost
    "Location" = $folder
    "ResourcePool" = $cl
    "Datastore" = $ds
    "DiskGB" = 1
    "DiskStorageFormat" = "Thin"
    "NumCpu" = 1
    "Floppy" = $false
    "CD" = $false
    "GuestId" = "other26xLinuxGuest"
    "MemoryMB" = 512
}
#

$vm1 = new-vm -name $vmname1 @vmsplat
$vm2 = new-vm -name $vmname2 @vmsplat



write-host -foregroundcolor Green "Attaching VMs $vmname1 and $vmname2 to $($ls1.display_name) and $($ls2.display_name) "

$null = $vm1 | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $ls1.display_name -confirm:$false
$null = $vm2 | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $ls2.display_name -confirm:$false


$null = $vm1 | Start-VM
$null = $vm2 | Start-VM


### CREATING NS GROUP BASED ON TAGS
write-host -foregroundcolor Green "Creating NSgroup with Dynamic Tag criteria"

$nsgroupmembership = @{}
$nsgroupmembership.Add("resource_type", "NSGroupTagExpression")
$nsgroupmembership.Add("scope", "production")
$nsgroupmembership.Add("target_type", "LogicalSwitch")
$nsgroupmembership.Add("tag", "web")
$nsgroupmembership.Add("scope_op", "EQUALS")
$nsgroupmembership.Add("tag_op", "EQUALS")


$specNsGroup = $serviceNsGroup.Help.create.ns_group.Create()
$specNsGroup.resource_type ="NSGroup"
$specNsGroup.display_name = "$nsgroupname"
$specNsGroup.membership_criteria.Add($nsgroupmembership) | Out-Null
$nsGroup = $serviceNsGroup.Create($specNsGroup)


### Creating Firewall Section
write-host -foregroundcolor Green "Creating Firewall section $firewallsectionName"

$anchorid = "dummyid"
$spec = $serviceFirewallSections.help.create.firewall_section.create()
$spec.display_name = "$firewallSectionName"
$spec.section_type = "LAYER3"
$spec.stateful = $True
$firewallsection = $serviceFirewallSections.Create($spec)

### Creating Firewall Rule

write-host -foregroundcolor Green "Creating Firewall rule $firewallrulename"

$sourceSpec1 = $serviceFirewallSectionRules.help.create.firewall_rule.sources.Element.Create()
$sourceSpec1.target_id = $nsgroup.id
$sourceSpec1.target_type = $nsgroup.resource_type

$spec = $serviceFirewallSectionRules.help.create.firewall_rule.create()
$spec.display_name = "$firewallRuleName"
$spec.action = "ALLOW"
# $spec.direction = "IN_OUT"
# $spec.ip_protocol="IPV4_IPV6"
$spec.resource_type="FirewallRule"
$spec.sources.Add($sourcespec1) | Out-Null
$rule = $serviceFirewallSectionRules.Create($firewallSection.id, $spec)

write-host -ForegroundColor Green "Completed"
write-host -ForegroundColor Green "I am adding members of $($LS1.display_name) and $($LS2.display_name) to $($nsGroup.display_name) via Tag "
write-host -ForegroundColor Cyan "To cleanup please Delete in the following order: "
write-host -ForegroundColor Cyan "Firewall Section $($firewallsection.display_name) "
write-host -ForegroundColor Cyan "NSgroup $($nsGroup.display_name) "
write-host -ForegroundColor Cyan "VMs $($vm1.name) and $($vm2.name) "
write-host -ForegroundColor Cyan "Router $($t1router.display_name) "
write-host -ForegroundColor Cyan "Logical Ports on $($LS1.display_name) and $($LS2.display_name) "
write-host -ForegroundColor Cyan "Logical Switches $($LS1.display_name) and $($LS2.display_name) "

write-host -ForegroundColor Green "!!Automation is fun!!"





# #Delete FW section
# $section = $serviceFirewallSections.List().results | ? {$_.display_name -eq $firewallsectionName}
# $null= $serviceFirewallSections.Delete($section.id)
# #Delete NSG
# $nsg = $serviceNsGroup.List().results | ? {$_.display_name -eq "$nsgroupname"}
# $null = $serviceNsGroup.Delete($nsg.id)
# #Delete VM
# get-vm Test* | stop-vm -confirm:$false
# get-vm Test* | remove-vm -DeletePermanently -confirm:$false

