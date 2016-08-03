
param (
    $IpAddress = "10.35.254.4" 
    )

    write-host -foregroundcolor Green "Below is the output if the IP address was detected by VMTools detection"
    Get-VM | Select Name, @{N="IP Address";E={@($_.Guest.IPAddress[0])}}, @{N="PowerState";E={@($_.PowerState)}}, @{N="VMTools Status";E={@($_.ExtensionData.Guest.ToolsStatus)}}, @{N="VMTools Version";E={@($_.Guest.ToolsVersion)}} | ? {$_."IP Address" -eq ("$IpAddress")} 
   

    write-host -foregroundcolor Green "Below is the output if the IP address was detected by NSX ARP IP Discovery"
    $vm = Get-NsxSpoofGuardPolicy | Get-NsxSpoofGuardNic 
    $vm.DetectedIpAddress | ? {$_."ipAddress" -eq ("$IpAddress")}


  
  

