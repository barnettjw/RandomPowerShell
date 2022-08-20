
function Search-CensysHosts() {
    # Uses the Censys API to find hosts on the internet
    
    # Required API Key: censys.io
    
    param($query, $apiId, $apiSecret)

    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($("$apiId" + ':' + "$apiSecret")))
    
    $headers = @{
        'Authorization' = "Basic $encodedCreds"
        'Content-Type'  = 'application/json'
    }

    $uri = 'https://search.censys.io/api/v2/hosts/search?q=$query'
    $response = Invoke-WebRequest -UseBasicParsing "$uri" -Headers $headers
    (($response.content | ConvertFrom-Json).result).hits
}