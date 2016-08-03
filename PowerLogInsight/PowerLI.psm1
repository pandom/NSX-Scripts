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

#
