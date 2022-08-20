# Get all sip address domains

# Required PowerShell Module: ActiveDirectory

$users = Get-ADUser -Filter {
    (msRTCSIP-UserEnabled -eq $true) -and (enabled -eq $true)
} -ResultSetSize 10000 -Properties msRTCSIP-PrimaryUserAddress, displayname

$sipAddresses = $users | Where-Object { 
    ($_.distinguishedname -ilike '*OU=Users,DC=ad,DC=example,DC=com') 
} | ForEach-Object {
    $sipDomain = $($_.'msRTCSIP-PrimaryUserAddress' -split '@')[1]
    $_ | Add-Member -MemberType NoteProperty -Name sipDomain -Value $sipDomain -Force
    $_ | Select-Object displayname, enabled, samaccountname, sipDomain
} 

$sipAddresses | Group-Object sipdomain | 
Select-Object name, count | Sort-Object count -Descending