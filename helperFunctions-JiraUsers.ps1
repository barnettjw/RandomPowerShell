
function Read-JiraCredentials() {
    # Helper Function: prompt for jira credentials

    $script:server = Read-Host 'Jira Server?'
    $script:username = Read-Host "Username for $script:server"
    $script:passwordSecure = Read-Host "Password for $script:username on $script:server" -AsSecureString
}

function Invoke-JiraAPI() {
    # Helper Function: wrapper around jira api

    [CmdletBinding()]param($uri)

    # if don't currently have credentials prompt for them
    if (-not ($script:server -and $script:username -and $script:passwordSecure)) { Read-JiraCredentials }

    # convert user/pass to basic auth headers
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($script:passwordSecure))
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f $script:username, $password)))
    $headers = @{Authorization = ('Basic {0}' -f $base64AuthInfo) }
    
    # invoke api call
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $rawResults = Invoke-WebRequest -Headers $headers -Uri $uri -ErrorAction Stop
        $rawResults.content | ConvertFrom-Json
    }
    catch {
        Get-RestError $_
    }
}

function Get-JiraUser() {
    # Helper Function: get a jira user returned as powershell object

    [CmdletBinding()]
    param(
        $server = $script:server,
        $username
    )

    try {
        $baseUri = "https://$script:server/rest/api/2"
        $uri = "$baseUri/user?username=$username&expand=groups,applicationRoles"
        $user = $(Invoke-JiraAPI -uri $uri -ErrorAction Stop )

        [pscustomobject]@{
            uri          = $($user.self)
            username     = $($user.name)
            active       = $($user.active)
            emailAddress = $($user.emailAddress)
            displayName  = $($user.displayName)
            groups       = $($user.groups.items.name)
            application  = $($user.applicationRoles.items.name)
        }
    }
    catch { Write-Warning $_ }
}

function Find-AllJiraUsers() {
    # Helper Function: find all jira users

    param(
        $server = $script:server,
        $baseUri = "https://$server/rest/api/2",
        $startAt = 0,
        $maxResults = 1000 # 1000 is max supported by api
    )

    # api will trucate to 1000 if more is requested
    # if more users are required your script will need implement paging logic

    # region - validate $maxResults
    if (($maxResults -isnot 'Int') -or ([int]$maxResults -le 0)) { 
        return Write-Warning "$maxResults is not positive integer. Please use a positive integer" 
    }

    if ([int]$maxResults -gt 1000) { 
        return Write-Warning '-maxResults accepts integers between 1 to 1000' 
    }
    #endregion

    try {
        $uri = "$baseUri/user/search?username=.&startAt=$startAt&maxResults=$maxResults"
        Invoke-JiraAPI -uri $uri -ErrorAction Stop 
    }
    catch { Write-Warning $_ }
}

function Get-JiraGroupMembers() {
    # Helper Function: get the members of the specified jira group

    param(
        $groupName,
        $server = $script:server,
        $baseUri = "https://$server/rest/api/2"
    )

    try {
        $results = Invoke-JiraAPI -uri "$baseUri/group/member?groupname=$groupName" -ErrorAction Stop
        $users = $results.values

        while (-not $results.islast) {
            $results = Invoke-JiraAPI -uri $results.nextpage -ErrorAction Stop
            $users += $($results).values
        }

        $users | Select-Object -Property * -ExcludeProperty avatarUrls
    }
    catch { Get-RestError $_ }
}

function Get-JiraUsers() {
    # wrapper script to provide progress bar for the get jira user operation

    param(
        $server = $script:server,
        [parameter(valuefrompipeline)]$users
    )
    
    $i = 0
    try {
        $maxResults = $users.Count
        $users | ForEach-Object {
            Write-Progress "Processing users on $server..." "$i of $($maxResults)" -CurrentOperation "user: $($_.name)" `
                -PercentComplete (($i / $maxResults) * 100)
            Get-JiraUser -server $server -username $_.name -ErrorAction Stop | Select-Object -Property * -ExcludeProperty avatarUrls
            $i++
        }
    }
    catch { Write-Warning $_ }
}