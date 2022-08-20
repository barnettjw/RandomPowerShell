$ports = @(
    [pscustomobject]@{ name = 'LDAP'; port = 389 },
    [pscustomobject]@{ name = 'LDAP over TLS'; port = 636 } ,
    [pscustomobject]@{ name = 'Global Catalogue'; port = 3268 },
    [pscustomobject]@{ name = 'Global Catalogue over TLS'; port = 3269 },
    [pscustomobject]@{ name = 'Kerberos'; port = 88 },
    [pscustomobject]@{ name = 'Kerberos Password Change'; port = 464 },
    [pscustomobject]@{ name = 'SMB'; port = 139 },
    [pscustomobject]@{ name = 'SMB over TLS'; port = 445 },
    [pscustomobject]@{ name = 'WMI'; port = 135 },
    [pscustomobject]@{ name = 'WinRM'; port = 5985 }
    [pscustomobject]@{ name = 'WinRM over TLS'; port = 5986 }
)

function Test-Ports() {
    # tests multiple ports specified as an array of objects against a computer

    param(
        [parameter(ValueFromPipeline)]$computer, 
        $ports = $ports, 
        $timeout = 3000
    )

    $conn = $(Test-NetConnection $computer -WarningAction SilentlyContinue)
    $resolved = $conn.NameResolutionSucceeded
    
    if ($resolved -and $ports) {
        $ports | ForEach-Object {
            $open = Test-Port -computer $computer -port $_.port -quiet -timeout $timeout
            $_ | Add-Member -MemberType NoteProperty -Name Open -Value $open -Force
        }
    }
    else {
        $ports | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name Open -Value $null -Force
        }
    }

    $ports
}