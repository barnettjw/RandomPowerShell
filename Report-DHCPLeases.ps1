<#
DHCP audit logs are stored as CSVs on the DHCP server, if audit log is enabled

to view event ids:
    https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd183591(v=ws.10)#dhcp-server-log-common-event-codes
    gci "C:\windows\system32\DhcpSrvLog-*.log" | select -First 1 | % { gc $_.PSPath } | select -First 30
#>

$results = Get-DhcpServerInDC | ForEach-Object {
    $auditLog = Get-DhcpServerAuditLog -ComputerName $_.dnsname
    if ($($auditLog.enable) -eq $true) {
        
        # get audit logs on server via psremoting
        Invoke-Command $_.dnsname {
            $i = 0
            
            # gets audit logs
            $logPath = $($using:auditLog).path
            Get-ChildItem "$logPath\DhcpSrvLog-*.log" | 
            ForEach-Object {
                # write progress per server, divides by 7 days a week
                Write-Progress -Activity $env:COMPUTERNAME `
                    -CurrentOperation $(Split-Path $($_.PSPath) -Leaf) `
                    -Status $('{0:P0}' -f ($i / 7)) `
                    -PercentComplete (($i / 7) * 100)

                #region - strip off comments above header and import as csv
                $content = Get-Content $($_.PSPath)

                $headerLineNumber = $($content | 
                    Select-String -SimpleMatch 'CorrelationID').LineNumber

                $content | Select-Object -Skip $($headerLineNumber - 1) | 
                ConvertFrom-Csv
                #endregion
                
                $i++
            }
        }
        
    }
} | 
# filter for new lease and renewed lease 
Where-Object { $_.id -eq 10 -or $_.id -eq 11 }

$results | 
Sort-Object Date, Description, 'Host Name', 'MAC Address', 'IP Address' -Unique |
Select-Object Date, Time, Description, 'Host Name', 'MAC Address', 'IP Address',
'VendorClass(ASCII)', PSComputerName
