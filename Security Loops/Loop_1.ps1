## Security Group loop for Groups and Tags ##
## Author: Anthony Burke t:@pandom_ b:networkinferno.net
## version 1.0
## July 2016
# Creating loops to ensure 1:1 SG/Tag mapping. Example to create loops. Ones below are based on the integer values in the brackets. The loop will repeat for each value in this. Current number below is 10. Could be thousands. These are populated with any string value.
    New-NsxFirewallSection "Hatred" > $null

    $ips10 = New-NsxIpSet -name "10" -IpAddress "10.0.0.0/8"

(1..250) | % {
    [string]$suffix = $_.ToString("0000")
    $st = New-NsxSecurityTag -name SG-TAG-$suffix
    $sg = New-NsxSecurityGroup -name SG-GROUP-$suffix -includemember ($st)
    $ips1 = New-NsxIpSet -name IP-$suffix -IpAddress 1.$($_).1.1
    Get-NsxFirewallSection "Hatred" | New-NsxFirewalLRule -name "Incarnate" -source $sg -destination ($ips10,$ips1) -action "allow" > $null
}
