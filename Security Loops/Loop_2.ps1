## Security Group loop for Groups and Tags ##
## Author: Anthony Burke t:@pandom_ b:networkinferno.net
## version 1.0
## July 2016
# Creating loops to ensure 1:1 SG/Tag mapping. Example to create loops. Ones below are based on a CSV file. This CSV file has a column titled SECURITYTAG and another titled SECURITYGROUP
#This will make based on CSV.
import-csv .\base-example.csv | % {
    $st = New-NsxSecurityTag -name $_.SECURITYTAG
    $sg = new-NsxSecurityGroup -name $_.SECURITYGROUP -includemember ($st)
}
