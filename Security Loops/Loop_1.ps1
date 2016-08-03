## Security Group loop for Groups and Tags ##
## Author: Anthony Burke t:@pandom_ b:networkinferno.net
## version 1.0
## July 2016
# Creating loops to ensure 1:1 SG/Tag mapping. Example to create loops. Ones below are based on the integer values in the brackets. The loop will repeat for each value in this. Current number below is 10. Could be thousands. These are populated with any string value.

(1..10) | % {
    [string]$suffix = $_.ToString("0000")
    $st = New-NsxSecurityTag -name SG-TAG-$suffix
    $sg = New-NsxSecurityGroup -name SG-GROUP-$suffix -includemember ($st)
}
