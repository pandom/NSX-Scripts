$cred = Get-Credential -user admin -password VMware1!
$server = "nsxmgr-01a.corp.local"
$port = "443"
$protocol = $connection.Protocol
$timeout = 10
$method = "get"
$headerDictionary = @{}
    $base64cred = [system.convert]::ToBase64String(
        [system.text.encoding]::ASCII.Getbytes(
            "$($cred.GetNetworkCredential().username):$($cred.GetNetworkCredential().password)"
        )
    )
    $headerDictionary.add("Authorization", "Basic $Base64cred")




$uri = "https://$server/api/v1/firewall/sections"
$response = invoke-webrequest -method $method -headers $headerDictionary -uri $uri -TimeoutSec $Timeout -contenttype "application/json"  -skipcertificatecheck
$result = $response.content | convertfrom-json

write-host -foregroundcolor green "$($result.result_count) firewall sections found"

$id = $result.results.id
foreach ($item in $id) {
    $ruleURI = "https://$server/api/v1/firewall/sections/$($item)/rules"
    $response = invoke-webrequest -method $method -headers $headerDictionary -uri $ruleURI -TimeoutSec $Timeout -contenttype "application/json"  -skipcertificatecheck
    $result = $response.content | convertfrom-json
    $resultnum = $result.result_count
    $resultsection = $result.results.section_id

    write-host -foregroundcolor green  "$resultnum rule(s) found in $resultsection "
    $result.results
}