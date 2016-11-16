#t: 8-way ECMP with BGP. 
#a: Anthony Burke
#ECMP 8-way
# Script's goal is to create an 8-way ECMP edge with upstream.

#          X (upstream router)
#          |
#          |
#     _______________    (ecmp network LS)
#     | | | | | | | |
#     X X X X X X X X    (8-node ecmp edges)
#     | | | | | | | |
#     ---------------    (transit LS)
#          |
#        (dlr)



param (

#Generic Edge requirements
	$ClusterName = 'Mgmt01',
	$DatastoreName = 'MgmtData',
	$CompClusterName = 'Compute01',
	$CompDatastoreName = 'CompData',
	$EdgeUplinkNetworkName = 'Internal',
	$Password = 'VMware1!VMware1!',
	$FormFactor = 'Compact',
	$DefaultSubnetBits = '24',
	$EdgeAs = '43214',
	$DlrAs = '52008',
	$upsteamAs = '23314',
#MgtVdS
	$MgtVds = 'Mgt_Trans_Vds',
#Logical Switches
	$EdgeToUpstreamLsName = 'ecmp-network',
	$DlrToEdgeLsName = 'transit-network',
	$ls1 = '172.16.201.1',
	$ls2 = '172.16.202.1',
	$ls3 = '172.16.203.1',
	$ls4 = '172.16.204.1',
	$ls5 = '172.16.205.1',
	$ls6 = '172.16.206.1',
	$ls7 = '172.16.207.1',
	$ls8 = '172.16.208.1',
	$ls9 = '172.16.209.1',
	$ls10 = '172.16.210.1',
#DLR Configuration
	$DlrUplinkPrimaryAddress = '172.16.20.1',
	$DlrRouterId = '172.16.20.2',
	$DlrName = "ecmp-dlr",
#Edge Configuration
	$edge0name = 'upstream-edge',
	$edge0uplinkaddress = '192.168.100.173',
	$edge0internaladdress = '172.16.10.1',

	$edge1name = 'ecmp-edge1',
	$edge1uplinkaddress = '172.16.10.11',
	$edge1internaladdress = '172.16.20.11',

	$edge2name = 'ecmp-edge2',
	$edge2uplinkaddress = '172.16.10.12',
	$edge2internaladdress = '172.16.20.12',

	$edge3name = 'ecmp-edge3',
	$edge3uplinkaddress = '172.16.10.13',
	$edge3internaladdress = '172.16.20.13',

	$edge4name = 'ecmp-edge4',
	$edge4uplinkaddress = '172.16.10.14',
	$edge4internaladdress = '172.16.20.14',

	$edge5name = 'ecmp-edge5',
	$edge5uplinkaddress = '172.16.10.15',
	$edge5internaladdress = '172.16.20.15',

	$edge6name = 'ecmp-edge6',
	$edge6uplinkaddress = '172.16.10.16',
	$edge6internaladdress = '172.16.20.16',

	$edge7name = 'ecmp-edge7',
	$edge7uplinkaddress = '172.16.10.17',
	$edge7internaladdress = '172.16.20.17',

	$edge8name = 'ecmp-edge8',
	$edge8uplinkaddress = '172.16.10.18',
	$edge8internaladdress = '172.16.20.18'


)



## Environment checks
    [int]$PowerCliMajorVersion = (Get-PowerCliVersion).major

    if ( -not ($PowerCliMajorVersion -ge 6 ) ) { throw 'This script requires PowerShell 6' }

    try {
        $Cluster = get-cluster $ClusterName -errorAction Stop
        $DataStore = get-datastore $DatastoreName -errorAction Stop
        $EdgeUplinkNetwork = get-vdportgroup $EdgeUplinkNetworkName -errorAction Stop
    }
    catch {
        throw 'Failed getting vSphere Inventory Item: $_'
    }

## Logical Switches

	$DlrToEdgeLs = Get-NsxTransportZone | New-NsxLogicalSwitch -name $DlrToEdgeLsName
	$EdgeToUpstreamLs = Get-NsxTransportZone | New-NsxLogicalSwitch $EdgeToUpstreamLsName

## Creating DLR

	# DLR Appliance has the uplink router interface created first.

	$DlrvNic0 = New-NsxLogicalRouterInterfaceSpec -type Uplink -Name $DlrToEdgeLsName -ConnectedTo $DlrToEdgeLs -PrimaryAddress $DlrUplinkPrimaryAddress -SubnetPrefixLength $DefaultSubnetBits

	# The DLR is created with the first vnic defined, and the datastore and cluster on which the Control VM will be deployed.
	$Dlr = New-NsxLogicalRouter -name $DlrName -ManagementPortGroup $EdgeUplinkNetwork -interface $DlrvNic0 -cluster $Cluster -datastore $Datastore

	$DlrTransitInt = get-nsxlogicalrouter | get-nsxlogicalrouterinterface | ? { $_.name -eq $DlrToEdgeLsname}
	Get-NsxLogicalRouter $DlrName | Get-NsxLogicalRouterRouting | Set-NsxLogicalRouterRouting -EnableBgp -LocalAs $DlrAs -enableEcmp -RouterId $DlrRouterId -confirm:$false | out-null

	#This is quite slow. I should go ahead and create the interfacespec here and then store them in a hash table. Then loop over table on DLR creation. it will be faster.
	$lifs = @($ls1,$ls2,$ls3,$ls4,$ls5,$ls6,$ls7,$ls8,$ls9,$ls10)

	foreach ($lif in $lifs) {
		$ls = Get-NsxTransportzone | New-NsxLogicalSwitch -name "Network-$lif"
		$int = Get-NsxLogicalRouter $dlrName | New-NsxLogicalRouterInterface -type Internal -Name "Network-$Lif" -ConnectedTo $Ls -PrimaryAddress $lif -SubnetPrefixLength $DefaultSubnetBits
	}

## Scoping Management DVS and cluster

	$EdgeToUpstreamLs =  $EdgeToUpstreamLs | Get-NsxBackingPortGroup | Where { $_.VDSwitch -match ("$MgtVds") }
	$TransitNetwork =  $DlrToEdgeLs | Get-NsxBackingPortGroup | Where { $_.VDSwitch -match ("$MgtVds") }

## Defining Edge Interface Specs
	$edge0vnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $Edge0UplinkAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeUplinkNetwork
	$edge0vnic1 = New-NsxEdgeInterfaceSpec -index 1 -Name 'Downlink' -type Internal -PrimaryAddress $Edge0InternalAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeToUpstreamLs

	$edge1vnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $Edge1UplinkAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeToUpstreamLs
	$edge1vnic1 = New-NsxEdgeInterfaceSpec -index 1 -Name 'Downlink' -type Internal -PrimaryAddress $Edge1InternalAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $TransitNetwork

	$edge2vnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $edge2UplinkAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeToUpstreamLs
	$edge2vnic1 = New-NsxEdgeInterfaceSpec -index 1 -Name 'Downlink' -type Internal -PrimaryAddress $edge2InternalAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $TransitNetwork

	$edge3vnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $edge3UplinkAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeToUpstreamLs
	$edge3vnic1 = New-NsxEdgeInterfaceSpec -index 1 -Name 'Downlink' -type Internal -PrimaryAddress $edge3InternalAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $TransitNetwork

	$edge4vnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $edge4UplinkAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeToUpstreamLs
	$edge4vnic1 = New-NsxEdgeInterfaceSpec -index 1 -Name 'Downlink' -type Internal -PrimaryAddress $edge4InternalAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $TransitNetwork

	$edge5vnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $edge5UplinkAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeToUpstreamLs
	$edge5vnic1 = New-NsxEdgeInterfaceSpec -index 1 -Name 'Downlink' -type Internal -PrimaryAddress $edge5InternalAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $TransitNetwork

	$edge6vnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $edge6UplinkAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeToUpstreamLs
	$edge6vnic1 = New-NsxEdgeInterfaceSpec -index 1 -Name 'Downlink' -type Internal -PrimaryAddress $edge6InternalAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $TransitNetwork

	$edge7vnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $Edge7UplinkAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeToUpstreamLs
	$edge7vnic1 = New-NsxEdgeInterfaceSpec -index 1 -Name 'Downlink' -type Internal -PrimaryAddress $Edge7InternalAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $TransitNetwork

	$edge8vnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $Edge8UplinkAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeToUpstreamLs
	$edge8vnic1 = New-NsxEdgeInterfaceSpec -index 1 -Name 'Downlink' -type Internal -PrimaryAddress $Edge8InternalAddress -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $TransitNetwork


## Creating Edge
	$Edge0 = New-NsxEdge -name $Edge0Name -cluster $Cluster -datastore $DataStore -Interface $edge0vnic0, $edge0vnic1 -Password $Password -FormFactor $FormFactor -FwDefaultPolicyAllow -AutoGenerateRules -enableSSH
	$Edge1 = New-NsxEdge -name $Edge1Name -cluster $Cluster -datastore $DataStore -Interface $edge1vnic0, $edge1vnic1 -Password $Password -FormFactor $FormFactor -FwEnabled:$False -FwDefaultPolicyAllow -AutoGenerateRules -enableSSH
	$Edge2 = New-NsxEdge -name $Edge2Name -cluster $Cluster -datastore $DataStore -Interface $edge2vnic0, $edge2vnic1 -Password $Password -FormFactor $FormFactor -FwEnabled:$False -FwDefaultPolicyAllow -AutoGenerateRules -enableSSH
	$Edge3 = New-NsxEdge -name $Edge3Name -cluster $Cluster -datastore $DataStore -Interface $edge3vnic0, $edge3vnic1 -Password $Password -FormFactor $FormFactor -FwEnabled:$False -FwDefaultPolicyAllow -AutoGenerateRules -enableSSH
	$Edge4 = New-NsxEdge -name $Edge4Name -cluster $Cluster -datastore $DataStore -Interface $edge4vnic0, $edge4vnic1 -Password $Password -FormFactor $FormFactor -FwEnabled:$False -FwDefaultPolicyAllow -AutoGenerateRules -enableSSH
	$Edge5 = New-NsxEdge -name $Edge5Name -cluster $Cluster -datastore $DataStore -Interface $edge5vnic0, $edge5vnic1 -Password $Password -FormFactor $FormFactor -FwEnabled:$False -FwDefaultPolicyAllow -AutoGenerateRules -enableSSH
	$Edge6 = New-NsxEdge -name $Edge6Name -cluster $Cluster -datastore $DataStore -Interface $edge6vnic0, $edge6vnic1 -Password $Password -FormFactor $FormFactor -FwEnabled:$False -FwDefaultPolicyAllow -AutoGenerateRules -enableSSH
	$Edge7 = New-NsxEdge -name $Edge7Name -cluster $Cluster -datastore $DataStore -Interface $edge7vnic0, $edge7vnic1 -Password $Password -FormFactor $FormFactor -FwEnabled:$False -FwDefaultPolicyAllow -AutoGenerateRules -enableSSH
	$Edge8 = New-NsxEdge -name $Edge8Name -cluster $Cluster -datastore $DataStore -Interface $edge8vnic0, $edge8vnic1 -Password $Password -FormFactor $FormFactor -FwEnabled:$False -FwDefaultPolicyAllow -AutoGenerateRules -enableSSH

	##Enable BGP on Edges
	
 	get-nsxedge -name $Edge0Name | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -RouterId $Edge0UplinkAddress -EnableEcmp -LocalAs $upsteamAs -confirm:$false | out-null 

	get-nsxedge -name $Edge1Name | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -RouterId $Edge1UplinkAddress -EnableEcmp -LocalAs $edgeAs -confirm:$false | out-null 
	get-nsxedge -name $Edge2Name | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -RouterId $Edge2UplinkAddress -EnableEcmp -LocalAs $edgeAs -confirm:$false | out-null 
	get-nsxedge -name $Edge3Name | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -RouterId $Edge3UplinkAddress -EnableEcmp -LocalAs $edgeAs -confirm:$false | out-null 
	get-nsxedge -name $Edge4Name | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -RouterId $Edge4UplinkAddress -EnableEcmp -LocalAs $edgeAs -confirm:$false | out-null 
	get-nsxedge -name $Edge5Name | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -RouterId $Edge5UplinkAddress -EnableEcmp -LocalAs $edgeAs -confirm:$false | out-null 
	get-nsxedge -name $Edge6Name | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -RouterId $Edge6UplinkAddress -EnableEcmp -LocalAs $edgeAs -confirm:$false | out-null 
	get-nsxedge -name $Edge7Name | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -RouterId $Edge7UplinkAddress -EnableEcmp -LocalAs $edgeAs -confirm:$false | out-null 
	get-nsxedge -name $Edge8Name | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -RouterId $Edge8UplinkAddress -EnableEcmp -LocalAs $edgeAs -confirm:$false | out-null
	

	## Define Edge to DLR Peering

	get-nsxedge -name $Edge1Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $dlrrouterid -RemoteAs $dlrAs -confirm:$false | Out-Null
	get-nsxedge -name $Edge2Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $dlrrouterid -RemoteAs $dlrAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge3Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $dlrrouterid -RemoteAs $dlrAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge4Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $dlrrouterid -RemoteAs $dlrAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge5Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $dlrrouterid -RemoteAs $dlrAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge6Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $dlrrouterid -RemoteAs $dlrAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge7Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $dlrrouterid -RemoteAs $dlrAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge8Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $dlrrouterid -RemoteAs $dlrAs -confirm:$false | Out-Null  

	## Define Edge to Upstream router peering

	get-nsxedge -name $Edge1Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge0internaladdress -RemoteAs $upsteamas -confirm:$false | Out-Null 
	get-nsxedge -name $Edge2Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge0internaladdress -RemoteAs $upsteamas -confirm:$false | Out-Null  
	get-nsxedge -name $Edge3Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge0internaladdress -RemoteAs $upsteamas -confirm:$false | Out-Null  
	get-nsxedge -name $Edge4Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge0internaladdress -RemoteAs $upsteamas -confirm:$false | Out-Null 
	get-nsxedge -name $Edge5Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge0internaladdress -RemoteAs $upsteamas -confirm:$false | Out-Null 
	get-nsxedge -name $Edge6Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge0internaladdress -RemoteAs $upsteamas -confirm:$false | Out-Null  
	get-nsxedge -name $Edge7Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge0internaladdress -RemoteAs $upsteamas -confirm:$false | Out-Null  
	get-nsxedge -name $Edge8Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge0internaladdress -RemoteAs $upsteamas -confirm:$false | Out-Null 

	## Upstream Router $edge0 to Edges

	get-nsxedge -name $Edge0Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge1UplinkAddress -RemoteAs $EdgeAs -confirm:$false | Out-Null
	get-nsxedge -name $Edge0Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge2UplinkAddress -RemoteAs $EdgeAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge0Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge3UplinkAddress -RemoteAs $EdgeAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge0Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge4UplinkAddress -RemoteAs $EdgeAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge0Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge5UplinkAddress -RemoteAs $EdgeAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge0Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge6UplinkAddress -RemoteAs $EdgeAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge0Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge7UplinkAddress -RemoteAs $EdgeAs -confirm:$false | Out-Null 
	get-nsxedge -name $Edge0Name | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress $edge8UplinkAddress -RemoteAs $EdgeAs -confirm:$false | Out-Null   

	## Configure DLR BGP

	get-nsxlogicalrouter -name $dlrName | Get-NsxLogicalRouterRouting | Set-NsxLogicalRouterRouting -EnableBgp -RouterId $dlrrouterid -forwardingAddress $dlrrouterid -protocoladdress $DlrUplinkPrimaryAddress -LocalAs $dlras -confirm:$false | out-null
		

	## Configure DLR BGP Neighbors

	Get-NsxLogicalRouter -name $dlrname | Get-NsxLogicalRouterRouting | Set-NsxLogicalRouterRouting -EnableBgpRouteRedistribution -confirm:$false | Out-Null
	Get-NsxLogicalRouter -name $dlrName | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterRedistributionRule -learner bgp -FromConnected -confirm:$false | Out-Null
	Get-nsxlogicalrouter -name $dlrname | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterBgpNeighbour -IpAddress $edge1InternalAddress -RemoteAs $EdgeAs -forwardingaddress $DlrUplinkPrimaryAddress  -protocoladdress $DlrRouterId -confirm:$false | Out-Null
	Get-nsxlogicalrouter -name $dlrname | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterBgpNeighbour -IpAddress $edge2InternalAddress -RemoteAs $EdgeAs -forwardingaddress $DlrUplinkPrimaryAddress  -protocoladdress $DlrRouterId -confirm:$false | Out-Null
	Get-nsxlogicalrouter -name $dlrname | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterBgpNeighbour -IpAddress $edge3InternalAddress -RemoteAs $EdgeAs -forwardingaddress $DlrUplinkPrimaryAddress  -protocoladdress $DlrRouterId -confirm:$false | Out-Null
	Get-nsxlogicalrouter -name $dlrname | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterBgpNeighbour -IpAddress $edge4InternalAddress -RemoteAs $EdgeAs -forwardingaddress $DlrUplinkPrimaryAddress  -protocoladdress $DlrRouterId -confirm:$false | Out-Null
	Get-nsxlogicalrouter -name $dlrname | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterBgpNeighbour -IpAddress $edge5InternalAddress -RemoteAs $EdgeAs -forwardingaddress $DlrUplinkPrimaryAddress  -protocoladdress $DlrRouterId -confirm:$false | Out-Null
	Get-nsxlogicalrouter -name $dlrname | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterBgpNeighbour -IpAddress $edge6InternalAddress -RemoteAs $EdgeAs -forwardingaddress $DlrUplinkPrimaryAddress  -protocoladdress $DlrRouterId -confirm:$false | Out-Null
	Get-nsxlogicalrouter -name $dlrname | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterBgpNeighbour -IpAddress $edge7InternalAddress -RemoteAs $EdgeAs -forwardingaddress $DlrUplinkPrimaryAddress  -protocoladdress $DlrRouterId -confirm:$false | Out-Null
	Get-nsxlogicalrouter -name $dlrname | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterBgpNeighbour -IpAddress $edge8InternalAddress -RemoteAs $EdgeAs -forwardingaddress $DlrUplinkPrimaryAddress  -protocoladdress $DlrRouterId -confirm:$false | Out-Null