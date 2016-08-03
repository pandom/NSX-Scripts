# author : anthony Burke
# company: VMware
#--------------------------------------------------
# ____   __   _  _  ____  ____  __ _  ____  _  _
# (  _ \ /  \ / )( \(  __)(  _ \(  ( \/ ___)( \/ )
#  ) __/(  O )\ /\ / ) _)  )   //    /\___ \ )  (
# (__)   \__/ (_/\_)(____)(__\_)\_)__)(____/(_/\_)
#     PowerShell extensions for NSX for vSphere
#--------------------------------------------------

#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the 'Software'), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
#of the Software, and to permit persons to whom the Software is furnished to do
#so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

### Note
#This powershell scrip should be considered entirely experimental and dangerous
#and is likely to kill babies, cause war and pestilence and permanently block all
#your toilets.  Seriously - It's still in development,  not tested beyond lab
#scenarios, and its recommended you dont use it for any production environment
#without testing extensively!

## Note: The OvfConfiguration portion of this example relies on this OVA. The securityGroup and Firewall configuration have a MANDATORY DEPENDANCY on this OVA being deployed at runtime. The script will fail if the conditions are not met. This OVA can be found here http://goo.gl/oBAFgq

# This paramter block defines global variables which a user can override with switches on execution.
param (

    #Infrastructure
    $vraEdgeName = 'vRA-Edge-032',
    $EdgeUplinkPrimaryAddress = '192.168.100.192',
    $EdgeUplinkSecondaryAddress = '192.168.100.193',
    $EdgeUplinkTertiaryAddress = '192.168.100.194',

    #vRA Nodes
    $VraVa01Name = 'vRA-VA-011',
    $VraVa01Ip = '10.26.38.47',
    $VraVa02Name = 'vRA-VA-02',
    $VraVa02Ip = '10.26.38.48',
    $VraIaas01Name = 'vRA-Iaas-01',
    $VraIaas01Ip = '10.26.38.49',
    $VraIaas02Name = 'vRA-Iaas-02',
    $VraIaas02Ip = '10.26.38.50',
    $VraIaas03Name = 'vRA-Iaas-03',
    $VraIaas03Ip = '10.26.38.49',
    $VraIaas04Name = 'vRA-Iaas-04',
    $VraIaas04Ip = '10.26.38.50',
    #Subnet
    $DefaultSubnetMask = '255.255.255.0',
    $DefaultSubnetBits = '24',

    #Port
    $HttpPort = '80',
    $HttpsPort = '443',


    #Compute
    $ClusterName = 'Mgmt01',
    $DatastoreName = 'MgmtData',
    $CompClusterName = 'Compute01',
    $CompDatastoreName = 'CompData',
    $EdgeUplinkNetworkName = 'Internal',
    $Password = 'VMware1!VMware1!',



    ##LoadBalancer
    $LbAlgo = 'ROUND-ROBIN',
    $MgrPoolName = 'PL-vRA-iaas-mgr',
    $WebPoolName = 'PL-vRA-iaas-web',
    $AppPoolName = 'PL-vRA-application-va',
    $MgrVipName = 'VP-vRA-Mgr',
    $WebVipName = 'VP-vRA-Web',
    $AppVipName = 'VP-vRA-App',
    $WebAppProfileName = 'AP-vRA-Web',
    $MgrAppProfileName = 'AP-vRA-Mgr',
    $AppAppProfileName = 'AP-vRA-App',
    $VipProtocol = 'HTTPS',
    ## Monitors for the three pools
    $ManagerMonitorName = 'MN-vRA-Manager',
    $ManagerMonitorInterval = '10',
    $ManagerMonitorTimeout = '10',
    $ManagerMonitorRetries = '3',
    $ManagerMonitorType = 'HTTPS',
    $ManagerMonitorMethod = 'GET',
    $ManagerMonitorUrl = '/VMPSProvision',
    $ManagerMonitorReceive = 'ProvisionService',
    $WebMonitorName = 'MN-vRA-Web',
    $WebMonitorInterval = '10',
    $WebMonitorTimeout = '10',
    $WebMonitorRetries = '3',
    $WebMonitorType = 'HTTPS',
    $WebMonitorMethod = 'GET',
    $WebMonitorUrl = '/wapi/api/status/web',
    $WebMonitorRecieve = 'REGISTERED',
    $ApplicationMonitorName = 'MN-vRA-Application',
    $ApplicationMonitorInterval = '10',
    $ApplicationMonitorTimeout = '10',
    $ApplicationMonitorRetries = '3',
    $ApplicationMonitorType = 'HTTPS',
    $ApplicationMonitorMethod = 'GET',
    $ApplicationMonitorUrl = '/wapi/api/services/health',
    $ApplicationMonitorExpected = '200 OK'

)



## Validation of PowerCLI version. PowerCLI 6 is requried due to OvfConfiguration commands.

    [int]$PowerCliMajorVersion = (Get-PowerCliVersion).major

    if ( -not ($PowerCliMajorVersion -ge 6 ) ) { throw 'OVF deployment tools requires PowerCLI version 6 or above' }

    try {
        $Cluster = get-cluster $ClusterName -errorAction Stop
        $DataStore = get-datastore $DatastoreName -errorAction Stop
        $EdgeUplinkNetwork = get-vdportgroup $EdgeUplinkNetworkName -errorAction Stop
        $CompCluster = Get-Cluster $CompClusterName -errorAction Stop
        $CompDataStore = get-datastore $CompDataStoreName -errorAction Stop
    }
    catch {
        throw 'Failed getting vSphere Inventory Item: $_'
    }

    # EDGE

    ## Defining the uplink and internal interfaces to be used when deploying the edge. Note there are two IP addreses on these interfaces. $EdgeInternalSecondaryAddress and $EdgeUplinkSecondaryAddress are the VIPs
    #$edgevnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $EdgeUplinkPrimaryAddress -SecondaryAddress $EdgeUplinkSecondaryAddress,$EdgeUplinkTertiaryAddress  -SubnetPrefixLength $DefaultSubnetBits

    # CONNECTED EDGE
    ## Uncomment the below two lines to connect to uplink portgroup defined in $EdgeUplinkNetworkName
    $EdgeUplinkNetwork = get-vdportgroup $EdgeUplinkNetworkName
    $edgevnic0 = New-NsxEdgeinterfacespec -index 0 -Name 'Uplink' -type Uplink  -PrimaryAddress $EdgeUplinkPrimaryAddress -SecondaryAddress $EdgeUplinkSecondaryAddress,$EdgeUplinkTertiaryAddress  -SubnetPrefixLength $DefaultSubnetBits -ConnectedTo $EdgeUplinkNetwork
    ## Secondary Interface (connected to DLR or Logical Switch) can be modified or uncommented. Ensure variables are populated in top parameter block
    #$edgevnic1 = New-NsxEdgeinterfacespec -index 1 -Name $TsTransitLsName -type Internal -ConnectedTo $TsTransitLs -PrimaryAddress $EdgeInternalPrimaryAddress -SubnetPrefixLength $DefaultSubnetBits -SecondaryAddress $EdgeInternalSecondaryAddress

    ## Deploy appliance with the defined uplinks
    write-host -foregroundcolor 'Green' "Creating $VraEdgeName"
    $VraEdge = New-NsxEdge -name $VraEdgeName -cluster $Cluster -datastore $DataStore -Interface $edgevnic0 -Password $Password


    write-host -foregroundcolor 'Green' "Setting $VraEdgeName firewall default rule to permit"
    $VraEdge = get-nsxedge $VraEdge.name
    $VraEdge.features.firewall.defaultPolicy.action = 'accept'
    $VraEdge | Set-NsxEdge -confirm:$false | out-null

    write-host -foregroundcolor 'Green' "Enabling LoadBalancing on $VraEdgeName"
    Get-NsxEdge $VraEdge | Get-NsxLoadBalancer | Set-NsxLoadBalancer -Enabled | out-null
    #Building the LB monitors
    write-host -foregroundcolor 'Green' "Building vRealize Automation health monitors on $VraEdgeName"

    $ManMon = Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | New-NsxLoadBalancerMonitor -Name $ManagerMonitorName -TypeHttps -interval  $ManagerMonitorInterval -timeout $ManagerMonitorTimeout -MaxRetries $ManagerMonitorRetries  -Method $ManagerMonitorMethod  -Url $ManagerMonitorUrl  -receive $ManagerMonitorReceive

    $WebMon = Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | New-NsxLoadBalancerMonitor -Name $WebMonitorName -TypeHttps -interval  $WebMonitorInterval -timeout $WebMonitorTimeout -MaxRetries $WebMonitorRetries   -Method $WebMonitorMethod  -Url $WebMonitorUrl  -receive $WebMonitorRecieve


    $AppMon =  Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | New-NsxLoadBalancerMonitor -Name $ApplicationMonitorName  -TypeHttps -interval  $ApplicationMonitorInterval -timeout $ApplicationMonitorTimeout -MaxRetries $ApplicationMonitorRetries    -Method $ApplicationMonitorMethod  -Url $ApplicationMonitorUrl  -Expected $ApplicationMonitorExpected

   # Create App Profiles.
    write-host -foregroundcolor 'Green' "Creating Application Profiles on $VraEdgeName"
    $WebAppProfile = Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | New-NsxLoadBalancerApplicationProfile -Name $WebAppProfileName  -Type $VipProtocol -SslPassthrough
    $MgrAppProfile = Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | New-NsxLoadBalancerApplicationProfile -Name $MgrAppProfileName  -Type $VipProtocol -SslPassthrough
    $AppAppProfile = Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | new-NsxLoadBalancerApplicationProfile -Name $AppAppProfileName  -Type $VipProtocol -SslPassthrough

    # Edge LB config - define pool members.  By way of example, we will use two different methods for defining pool membership.  Webpool via predefine memberspec first...


    $webpoolmember1 = New-NsxLoadBalancerMemberSpec -name $VraIaas01Name -IpAddress $VraIaas01Ip -Port $HttpsPort
    $webpoolmember2 = New-NsxLoadBalancerMemberSpec -name $VraIaas02Name -IpAddress $VraIaas02Ip -Port $HttpsPort

    write-host -foregroundcolor 'Green' "Creating Application Pool $WebPoolName on $VraEdgeName"
    # ... And create the web pool
    $WebPool =  Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | New-NsxLoadBalancerPool -name $WebPoolName -Description 'vRA Web Pool' -Transparent:$false -Monitor $WebMon -Algorithm $LbAlgo -MemberSpec $webpoolmember1,$webpoolmember2

    # ... And now add the pool members
    $mgrpoolmember1 = New-NsxLoadBalancerMemberSpec -name $VraIaas03Name -IpAddress $VraIaas03Ip -Port $HttpsPort
    $mgrpoolmember2 = New-NsxLoadBalancerMemberSpec -name $VraIaas04Name -IpAddress $VraIaas04Ip -Port $HttpsPort

    # Now, method two for the App Pool  Create the pool with empty membership.
    write-host -foregroundcolor 'Green' "Creating Application Pool $MgrPoolName on $VraEdgeName"
    $MgrPool = Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | New-NsxLoadBalancerPool -name $MgrPoolName -Description 'vRA Manager Pool' -Transparent:$false -Monitor $ManMon -Algorithm $LbAlgo -Memberspec $mgrpoolmember1,$mgrpoolmember2

    # Creating the App Pool and its members
    $AppPoolmember1 = New-NsxLoadBalancerMemberSpec -name $VraVa01Name -IpAddress $VraVa01Ip -Port $HttpsPort
    $AppPoolmember2 = New-NsxLoadBalancerMemberSpec -name $VraVa02Name -IpAddress $VraVa02Ip -Port $HttpsPort

    # Now, method two for the App Pool  Create the pool with empty membership.
    write-host -foregroundcolor 'Green' "Creating Application Pool $AppPoolName on $VraEdgeName"
    $AppPool = Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | New-NsxLoadBalancerPool -name $AppPoolName -Description 'vRA Application Pool' -Transparent:$false -Algorithm $LbAlgo -Monitor $AppMon -Memberspec $AppPoolmember1,$AppPoolmember2

    

    # Create the VIPs for the relevent WebPools. Applied to the Secondary interface variables declared.
    write-host -foregroundcolor 'Green' "Creating VIPs $WebVipName, $AppVipName, and $MgrVipName"
    Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | Add-NsxLoadBalancerVip -name $WebVipName -Description $WebVipName -ipaddress $EdgeUplinkPrimaryAddress  -Port $HttpsPort -Protocol $VipProtocol -ApplicationProfile $WebAppProfile -DefaultPool $WebPool -AccelerationEnabled | out-null
    Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | Add-NsxLoadBalancerVip -name $MgrVipName -Description $MgrVipName -ipaddress $EdgeUplinkSecondaryAddress  -Port $HttpsPort -Protocol $VipProtocol -ApplicationProfile $MgrAppProfile -DefaultPool $MgrPool -AccelerationEnabled | out-null
    Get-NsxEdge $vraEdgeName | Get-NsxLoadBalancer | Add-NsxLoadBalancerVip -name $AppVipName -Description $AppVipName -ipaddress $EdgeUplinkTertiaryAddress -Protocol $VipProtocol -Port $HttpsPort -ApplicationProfile $AppAppProfile  -DefaultPool $AppPool -AccelerationEnabled | out-null


write-host -foregroundcolor 'Green' "Edge $vraEdgeName created"


