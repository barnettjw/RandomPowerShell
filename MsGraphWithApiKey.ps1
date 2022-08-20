# Example of how to authenticate to MS Graph using PowerShell
# Uses Invoke-OAuth and ConvertFrom-Jwt functions

Select-MgProfile -Name 'beta'
Import-Module Microsoft.Graph

$params = @{
    clientId     = $clientId
    clientSecret = $clientSecret
    tenantId     = $azADTenant
    resource     = 'https://graph.microsoft.com'
    uri          = "https://login.microsoftonline.com/$azADTenant/oauth2/token"
}

$accessToken = $(Invoke-OAuth @params)

Connect-MgGraph -AccessToken $accessToken

# To Debug Authentication Issues
ConvertFrom-Jwt -AccessToken $accessToken -MsGraph