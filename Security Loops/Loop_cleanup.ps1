#Cleanup from loops


Get-NsxSecuritytag | ? {$_.name -match ("SG-TAG-0*")} | remove-nsxsecuritytag -force -confirm:$false
Get-NsxSecurityGroup | ? {$_.name -match ("SG-GROUP-0*")} | remove-nsxsecuritygroup -force -confirm:$falseH
