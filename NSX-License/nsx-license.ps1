# NSX licence via PowerCLI
#a. anthony burke
#t. @pandom
#c. This script will licence NSX for vSphere via PowerCLI. It requires a connection to vCenter along with a valid licence. Kudos to Gavin for helping me find nsx-netsec via MOB.

param (
  $license = "INSERT LICENCE HERE"
)



$ServiceInstance = Get-View ServiceInstance
$LicenseManager = Get-View $ServiceInstance.Content.licenseManager
$LicenseAssignmentManager = Get-View $LicenseManager.licenseAssignmentManager
$LicenseAssignmentManager.UpdateAssignedLicense("nsx-netsec",$license,$NULL)

# The following can be used to check an assigned licence.
#$CheckLicense = $$LicenseAssignmentManager.QueryAssignedLicenses("nsx-netsec")
#$CheckLicense.AssignedLicense
