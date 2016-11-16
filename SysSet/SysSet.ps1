#SysSet - A syslog configuration tool for NSX.

param (

    [string[]]$SyslogIPaddress = @("192.168.100.189, 192.168.100.190"),
    [string]$SyslogProtocol = "udp",
    [string]$SyslogLevel = "debug",
    [string]$SyslogStatus = "true"
)


# Collect the routers and edges
$Edges = Get-NsxEdge
#$Dlrs = Get-NsxLogicalRouter
# Add Controllers

    foreach ($edge in $edges) {
        
        
        $status = $edge.features.syslog.enabled

        if ($status -eq "false"){
            write-host -foregroundcolor yellow "Enabling Syslog for $($edge.name)"
            #Updates from false to true
            $edge.features.syslog.enabled = "$SyslogStatus"

            #Creating the XML that is required that is mising. serverAddresses -> ipAddress is missing
            #and is required when enabling. Cannot enable without it.

            $newElement = $Edge.OwnerDocument.CreateElement("serverAddresses")
            Add-XmlElement -xmlRoot $newelement -xmlElementName "ipAddress" -xmlElementText "$SyslogIpAddress"
            $edge.features.syslog.AppendChild($newElement) | out-null
    
            $edge | Set-NsxEdge -confirm:$false | out-null

            write-host -foregroundcolor green "Configuring Syslog values for $($edge.name)"
            #recollecting Edge for latest revision
            $edge = Get-NsxEdge -name $($edge.name)
            
            $edge.features.syslog.protocol = "$SyslogProtocol"
            $edge.vseLogLevel = "$SyslogLevel"
            $edge | Set-NsxEdge -confirm:$false | out-null

        }
        else {
            
            $edge.features.syslog.serverAddresses.ipAddress = "$SyslogIpAddress"
            $edge.features.syslog.protocol = "$SyslogProtocol"
            $edge.vseLogLevel = "$SyslogLevel"
            write-host -foregroundcolor green "Updating Syslog on $($edge.name)"
            $edge | Set-NsxEdge -confirm:$false | out-null
        }
            
            
    }
    
## UNTESTED
    # foreach ($dlr in $dlrs){

    #      $status = $dlr.features.syslog.enabled

    #     if ($status -eq "false"){
    #         write-host -foregroundcolor yellow "Enabling Syslog for $($dlr.name)"
    #         #Updates from false to true
    #         $dlr.features.syslog.enabled = "$SyslogStatus"

    #         #Creating the XML that is required that is mising. serverAddresses -> ipAddress is missing
    #         #and is required when enabling. Cannot enable without it.

    #         $newElement = $dlr.OwnerDocument.CreateElement("serverAddresses")
    #         Add-XmlElement -xmlRoot $newelement -xmlElementName "ipAddress" -xmlElementText "$SyslogIpAddress"
    #         $dlr.features.syslog.AppendChild($newElement) | out-null
    
    #         $dlr | Set-NsxLogicalRouter -confirm:$false

    #         write-host -foregroundcolor green "Configuring Syslog values for $($dlr.name)"
    #         #recollecting Edge for latest revision
    #         $dlr = Get-NsxLogicalRouter -name $($dlr.name)
            
    #         $dlr.features.syslog.protocol = "$SyslogProtocol"
    #         $dlr.vseLogLevel = "$SyslogLevel"
    #         $dlr | Set-NsxLogicalRouter -confirm:$false | out-null

    #     }
    #     else {
            
    #         $dlr.features.syslog.serverAddresses.ipAddress = "$SyslogIpAddress"
    #         $dlr.features.syslog.protocol = "$SyslogProtocol"
    #         $dlr.vseLogLevel = "$SyslogLevel"
    #         write-host -foregroundcolor green "Updating Syslog on $($dlr.name)"
    #         $dlr | Set-NsxLogicalRouter -confirm:$false | out-null
    #     }
    # }