#Slack Integration
#
#
#
#todo: Deal with secure tokens

function Set-SlackNotification{
    <#
    .SYNOPSIS
    Connects to Slack instance and posts a message to a given channel 
    .DESCRIPTION
    This function, Set-SlackNotification, builds a message that is posted to Slack. This allows notification sent to a Slack channel. 

    This can be used as a foundation for chat ops.

    .EXAMPLE
    This example show show to create a new default user

    PS C:\> Set-SlackNotification -token $Token -Text 'The script was successful' -Channel General -BotName = 'Singapore Lab Bot'
    #>


    Param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [String]$Token,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [String]$Text,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [String]$Channel,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [String]$BotName = 'Singapore Bot',
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [String]$Icon
    )

    # If the token variable is not defined in initial call then a token.txt file is used containing token
    if (!$token)
    {
        $token = Get-Content -Path "$SlackToken\token.txt"
    }
    # Here is the body of the message created from a hash table
    $PostMessage =@{
        token="$Token";
        channel="$Channel";
        text="$Text";
        username="$BotName";
        icon_url="$Icon"
    }

    $global:post = Invoke-RestMethod -Uri $Uri -Body $PostMessage
    $global:post
}