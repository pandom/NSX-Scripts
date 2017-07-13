# FQDN IP Set population tool
# a: anthony burke
# g: github.com/pandom/
# t: pandom_
# This should be run as a cronjob every X hours

param(
    $domainname = "news.com.au"
    )
#Internal, non custom variables
$FQDNIpSetName = "IPS-$domainname-v4"
$FQDNIpSetName6 = "IPS-$domainname-v6"
$existingIp = Get-NsxIpset -name $FQDNIpSetName
$existingIp6 = Get-NsxIpset -name $FQDNIpSetName6

    if (!$existingIp){
        $existingIp = New-NsxIpSet -name "$FQDNIpSetName" 
    }
    if (!$existingIp6){
        $existingIp6 = New-NsxIpSet -name "$FQDNIpSetName6" 
    }
# Perform DNS lookup
$updatedIp = [System.Net.Dns]::GetHostAddressesAsync($domainname)
$ipv4only = $updatedip.Result | ? {$_.AddressFamily -eq "InterNetwork"}
$ipv6only = $updatedip.Result | ? {$_.AddressFamily -eq "InterNetworkV6"}  
$updatedIps = $ipv4only.IpAddressToString
$updatedIps6 = $ipv6only.IpAddressToString

$Global:array = @()
$Global:array += $updatedIps
$Global:array6 = @()
$Global:array6 += $updatedIps6
#Add New IPv4 Addresses from $updatedIPs
    if ($updatedIps.count -gt '0') {
        write-host "Attempting to add $($array.length) IPv4 address(es) to $FQDNIpSetName"
        $Global:FQDNIpSet = Get-NsxIpSet -name $FQDNIpSetName | Add-NsxIpSetMember -IPAddress $array
    }
# #Add New IPv6 Addresses from $updatedIPs6
    if ($updatedIps6.count -gt '0') {
        write-host "Attempting to add $($array6.length) IPv6 address(es) to $FQDNIpSetName6"
        $Global:FQDNIpSet6 = Get-NsxIpSet -name $FQDNIpSetName6 | Add-NsxIpSetMember -IPAddress $array6
    }    
#Remove old IPv4 Addresses if new $updatedIPs are added
write-host "Tidying IPv4 entries"
    if ($existingip.value -gt 0){
        try {
            $splitEIp = $existingip.value.Split(",")
            $global:existingipArray = @()
            foreach ($eip in $splitEIp) {
                foreach ($ipv4 in $ipv4only) {
                    if ($eip -ne $ipv4){
                        $global:existingipArray += $eip
                    }
                }  
            }
            $global:purgearray = $existingiparray | Select -Unique   
            if ($purgearray.count -gt '0'){
                #write-host "Attempting to remove $($purgearray.count) stale IP Addresses from $FQDNIpSetName"
                $null = Get-NsxIpSet -name $FQDNIpSetName | Remove-NsxIpSetMember -IPaddress $global:purgearray
            }     
        }
        catch {
           #write-host "No stale IPv4 entries to remove"
        }
    }  
#Remove old IPv6 Addresses if new $updatedIPs6 are added
write-host "Tidying IPv6 entries"
    if ($existingip6.value -gt 0){
                try {
                    $splitEIp6 = $existingip6.value.Split(",")      
                    $global:existingipArray6 = @()
                    foreach ($eip6 in $splitEIp6) {
                        foreach ($ipv6 in $ipv6only) {
                            if ($eip6 -ne $ipv6){
                                $global:existingipArray6 += $eip6
                            }
                        }  
                    }
                    $global:purgearray6 = $existingiparray6 | Select -Unique   
                    if ($purgearray6.count -gt '0'){
                        #write-host "Attempting to remove $($purgearray6.count) stale IP Addresses from $FQDNIpSetName6"
                        $null = Get-NsxIpSet -name $FQDNIpSetName6 | Remove-NsxIpSetMember -IPaddress $global:purgearray6
                    }     
                }
                catch {
                    #write-host "No stale IPv6 entries to remove"
                }
            }  

    

    


  