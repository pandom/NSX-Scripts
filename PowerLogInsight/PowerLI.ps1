# PowerLogInsight
# a: Anthony Burke
# b: networkinferno.net
# GLOBAL DEFINITION - Only once
if ( -not ("TrustAllCertsPolicy" -as [type])) {

    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

}
function New-LogInsightDefaultUser {

    <#
    .SYNOPSIS
    Connects to Log Insight to create a new user on initial bootstrap.
    .DESCRIPTION
    The New-LogInsightDefaultUser is a one time call to create the default user on deployment. This is accessed one time only across an unauthenticated API call. Successful execution of this cmdlet results in the denial of subsequent Default User calls.

    .EXAMPLE
    This example show show to create a new default user

    PS C:\> New-LogInsightDefaultUser -server 192.168.100.97 -username Admin -password VMware1! -provider Local
    #>
        param (
                [Parameter (Mandatory=$True)]
                    [ValidateNotNullOrEmpty()]
                    [string]$userName,
                [Parameter (Mandatory=$True)]
                    [ValidateNotNullOrEmpty()]
                    [string]$Password,
                [Parameter (Mandatory=$false)]
                    [ValidateNotNullOrEmpty()]
                    [string]$Email,
                [Parameter (Mandatory=$True)]
                    [ValidateNotNullorEmpty()]
                    [string]$Server
                )

    $Port = 9000
    $URI = "http://$($server):$($port)/api/v1/deployment/new"
    $Body=[pscustomobject]@{
        "user" = [pscustomobject]@{
                "userName" = $userName;
                "password" = $Password
                }
        }

    $JsonBody = $Body | ConvertTo-Json
    $NewUser = Invoke-RestMethod -method "POST" -URI $URI -body $JsonBody -ContentType "application/json"
    $NewUser
}


function Connect-LogInsightServer {

    <#
    .SYNOPSIS
    Creates a connection to a given Log Insight server.
    .DESCRIPTION
    The Connect-LiServer command creates a session based on username to the Log Insight cluster.

    .EXAMPLE
    PS C:\> Connect-LiServer -server 192.168.100.97 -username admin -password VMware1!
    #>

    param (
        [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [string]$Server,
        [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [string]$Username,
        [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [string]$Password,
        [Parameter (Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [bool]$ValidateCertificate=$false,
        [Parameter (Mandatory=$false)]
            [ValidateNotNullorEmpty()]
            [switch]$DefaultLogInsightConnection=$true
        )
    #Ignore CertificatePolicy
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    $body=[pscustomobject]@{
        "provider" = "Local";
        "username" = $username;
        "password" = $password
    }

    $Port = "443"
    $Method = "POST"
    $Uri = "https://$($server):$($port)/api/v1/sessions"
    $Session = Invoke-RestMethod -method $method -uri $uri -body (ConvertTo-Json $body) -ContentType "application/json"

     $Connection=[pscustomobject]@{
        "Server" = $Server;
        "Session" = $Session.sessionId;
        "Port" = "443";
        "Protocol" = "https"


    }
   if ($DefaultLogInsightConnection){
        set-variable -name DefaultLogInsightConnection -value $connection -scope Global
   }
   $Authkey = $Session.sessionId
   $Global:Header= @{ "Authorization" = "Bearer "+ "$authkey" }
   $Connection
}


function Disconnect-LogInsightServer {

    <#
    .SYNOPSIS
    Destroys the $DefaultNSXConnection global variable if it exists.

    .DESCRIPTION
    REST is not connection oriented, so there really isnt a connect/disconnect
    concept.  Disconnect-NsxServer, merely removes the $DefaultNSXConnection
    variable that PowerNSX cmdlets default to using.

    .EXAMPLE
    Connect-NsxServer -Server nsxserver -username admin -Password VMware1!

    #>
    if (Get-Variable -Name DefaultLogInsightConnection -scope global ) {
        Remove-Variable -name DefaultLogInsightConnection -scope global
    }
}




#export-ModuleMember function Connect-LiServer

function invoke-LogInsightRestMethod{

    <#
    .SYNOPSIS
    The invoke-LogInsightRestMethod uses the default connection to manipulate the Log Insight API
    .DESCRIPTION


    .EXAMPLE
    PS C:\> invoke-LogInsightRestMethod -body $body -method $method -uri $uri
    #>

    param(
        [Parameter (Mandatory=$True)]
            [ValidateSet("GET","PUT","POST","PATCH","DELETE")]
            [string]$Method,
        [Parameter (Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [PsCustomObject]$Body,
        [Parameter (Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [System.Collections.Hashtable]$Headers,
        [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [string]$Uri
        )

#Contstruct the right URI

    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$URI"
    $BodyString = $Body | ConvertTo-Json

    $Global:LogInsightMethod = Invoke-RestMethod -method $Method -URI $ActiveURI -body $BodyString -Headers $Header -ContentType "application/json"

    $LogInsightMethod
}

function Get-LogInsightVersion {

    <#
    .SYNOPSIS
    Checks the version of VMware Log Insight
    .DESCRIPTION
    This function will check the version of VMware Log Insight.
    The API was introduced in version 3.0.

    .EXAMPLE
    PS C:\> Get-LogInsightVersion
    #>

    $Uri = "api/v1/version"
    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"
    $Version = Invoke-RestMethod -method GET -URI $ActiveURI -Headers $Header  -ContentType "application/json"

    $Version

}

#function Get-LogInsightIlb{
#
#    <#
#    .SYNOPSIS
#    This will retrieve the if the Log Insight Integrated Load Balancer (ILB) is configured.
#    .DESCRIPTION
#    This function will check the version of VMware Log Insight.
#    The ILB was introduced in Log Insight 3.0 and higher. Log Insight can have numerous ILB's configured. This Virtual IP address allows a single IP address (and assocaited FQDN) represent a cluster. This ensures consistent log ingestion if a cluster node goes down.
#
#    .EXAMPLE
#    PS C:\> Get-LogInsightIlb
#    #>
#
#    $Uri = "api/v1/ilb"
#    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"
#
#    $Ilb = Invoke-RestMethod -method GET -URI $ActiveURI -Headers $Header -ContentType "application/json"
#
#    $Ilb
#}
#
#
#function Get-LogInsightIlbStatus{
#
#    <#
#    .SYNOPSIS
#    Checks the version of VMware Log Insight
#    .DESCRIPTION
#    This function will check the version of VMware Log Insight.
#    The API was introduced in version 3.0.
#
#    .EXAMPLE
#    PS C:\> Get-LogInsightVersion
#    #>
#
#    $Uri = "api/v1/ilb/status"
#    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"
#
#    $IlbStatus = Invoke-RestMethod -method GET -URI $ActiveURI -Headers $Header -ContentType "application/json"
#
#    $IlbStatus
#}

#####
#####
#####
#####

##### TEST THESE FUNCTIONS

#####
#####
#####
function Get-LogInsightLicense {

     <#
    .SYNOPSIS
    Checks the licence of VMware Log Insight
    .DESCRIPTION
    This function will check the version of VMware Log Insight.
    The API was introduced in version 3.0.

    .EXAMPLE
    PS C:\> Get-LogInsightLicense
    #>

    $Uri = "api/v1/licenses"
    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"

    $License = Invoke-RestMethod -method GET -URI $ActiveURI -Headers $Header -ContentType "application/json"


    $License=[pscustomobject]@{
        "License" = $License.licenses;
        "License State" = $License.licenseState;
        "CPU units" = $License.hasCpu;
        "OSI units" = $License.hasOsi
        }
    $License

}

function Set-LogInsightLicense {

     <#
    .SYNOPSIS
    Sets the license of VMware Log Insight
    .DESCRIPTION
    This function will check the version of VMware Log Insight.
    The API was introduced in version 3.0.

    .EXAMPLE
    PS C:\> Get-LogInsightVersion
    #>
    param (
    [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [string]$License

    )

    $Uri = "api/v1/licenses"
    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"

    $Body=[pscustomobject]@{
        "key" = "$License"
    }

    $JsonBody = $Body | ConvertTo-Json
    $SetKey = Invoke-RestMethod -method POST -URI $ActiveURI -Body $JsonBody -Headers $Header -ContentType "application/json"

    $ActiveKey = Get-LogInsightLicense

    $ActiveKey

    $License=[pscustomobject]@{
        "License" = $License.licenses;
        "License State" = $License.licenseState;
        "CPU units" = $License.hasCpu;
        "OSI units" = $License.hasOsi
        }
    $License

}

function Get-LogInsightvSphereIntegration {

    <#
    .SYNOPSIS
    Sets the license of VMware Log Insight
    .DESCRIPTION
    This function will check the version of VMware Log Insight.
    The API was introduced in version 3.0.

    .EXAMPLE
    PS C:\> Get-LogInsightvSphereIntegration
    #>


    $Uri = "api/v1/vsphere"
    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"

    $vSphere = Invoke-RestMethod -method GET -URI $ActiveURI -Body $JsonBody -Headers $Header -ContentType "application/json"

    $vSphere


  }


function Set-LogInsightvSphereIntegration {

    <#
    .SYNOPSIS
    Sets the license of VMware Log Insight
    .DESCRIPTION
    This function will check the version of VMware Log Insight.
    The API was introduced in version 3.0.

    .EXAMPLE
    PS C:\> Get-LogInsightVersion
    #>
    param (
    [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [string]$HostName,
    [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [string]$UserName,
    [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [string]$Password

    )

    $body=[pscustomobject]@{
        "hostname" = $HostName;
        "username" = $UserName;
        "password" = $PassWord;
        "vsphereEventsEnabled" = "true"
    }

    $JsonBody = $Body | ConvertTo-Json
    $Uri = "api/v1/vsphere"
    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"

    $Configure = Invoke-RestMethod -method POST -URI $ActiveURI -Body $JsonBody -Headers $Header -ContentType "application/json"

    Get-LogInsightvSphereIntegration

    $Configured


  }

#function Get-LogInsightClusterNode {
#     <#
#    .SYNOPSIS
#    Returns any confgiured Clusters in VMware Log Insight
#    .DESCRIPTION
#    This will check and return any configured Log Insight Clusters.
#
#    .EXAMPLE
#    PS C:\> Get-LogInsightCluster
#    #>
#
#    $Uri = "api/v1/cluster/nodes"
#    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"
#
#    $Cluster = Invoke-restMethod -method GET -URI $ActiveURI -Headers $Header -ContentType "application/json"
#
#    #Prints contents of IRM stored in $Cluster
#    $Cluster=[pscustomobject]@{
#        "Node hostname" = $Cluster.hostname;
#        "Status" = $Cluster.licenseState;
#        "Uptime" = $Cluster.uptime;
#        "fullversion" = $Cluster.fullversion;
#        "Upgrading?" = $Cluster.upgradeInProgress
#        }
#   $Cluster
#}

#function Set-LogInsightClusterNodeRegistration{
#
#      <#
#    .SYNOPSIS
#    Register a node member in VMware Log Insight cluster
#    .DESCRIPTION
#    This will check and return any configured Log Insight Clusters.
#
#    .EXAMPLE
#    PS C:\> Get-LogInsightCluster
#    #>
#
#    param(
#        [Parameter (Mandatory=$True)]
#            [ValidateNotNullOrEmpty()]
#            [string]$workerAddress,
#        [Parameter (Mandatory=$False)]
#            [ValidateNotNullOrEmpty()]
#            [PsCustomObject]$workerPort="16520"
#
#        )
#
#    $body=[pscustomobject]@{
#        "workerAddress" = $workerAddress;
#        "workerPort" = $workerPort
#
#    }
#
#    $JsonBody = $body | ConvertTo-Json
#    $Uri = "api/v1/cluster/workers"
#    $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"
#
#}


#function Set-LogInsightClusterNode{
#
#      <#
#    .SYNOPSIS
#    Performs operations against an invidual cluster node
#    .DESCRIPTION
#    This will check and return any configured Log Insight Clusters.
#
#    .EXAMPLE
#    PS C:\> Get-LogInsightCluster
#    #>
#
#    param(
#        [Parameter (Mandatory=$True)]
#            [ValidateSet("Approve","Deny","Upgrade","Pause","Resume")]
#            [String]$Action,
#        [Parameter (Mandatory=$True)]
#            [ValidateScript({ Get-LogInsightClusterNode $_ })]
#            [String]$WorkerToken,
#        [Parameter (Mandatory=$False)]
#            [ValidateNotNullOrEmpty()]
#            [string]$workerAddress,
#        [Parameter (Mandatory=$False)]
#            [ValidateNotNullOrEmpty()]
#            [string]$workerPort="16520"
#
#            )
#    $body=[pscustomobject]@{
#        "workerAddress" = $workerAddress
#        "workerPort" = $workerPort;
#
#    }
#
#    $JsonBody = $body | ConvertTo-Json
#    $Uri = "api/v1/cluster/workers"
#     $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"
#    $ClusterNode = Invoke-RestMethod -method PUT -Uri $ActiveURI -body $JsonBody -Headers $Header -ContentType "application/xml"
#    $Cluster = Get-LogInsightCluster
#    $Cluster
#}



# function Get-LogInsightClusterNode{

#     .SYNOPSIS
#     Sets the license of VMware Log Insight
#     .DESCRIPTION
#     This function will check the version of VMware Log Insight.
#     The API was introduced in version 3.0.

#     .EXAMPLE
#     PS C:\> Get-LogInsightClusterNode

#     PS C:\> Get-LogInsightCluster | Get-LogInsightClusterNode -node


#     $Uri = "api/v1/cluster/nodes"
#     $ActiveURI = "$($DefaultLogInsightConnection.protocol)://$($DefaultLogInsightConnection.server):$($DefaultLogInsightConnection.port)/$Uri"

#     $Node

# }
