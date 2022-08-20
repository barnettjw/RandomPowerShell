function Get-Tls1Connection() {
    # Get events of TLS 1.0 connections to a server

    # Requires SChannel Logging enabled on the server
    # https://docs.microsoft.com/en-us/troubleshoot/developer/webapps/iis/health-diagnostic-performance/enable-schannel-event-logging

    param()
    Get-WinEvent -FilterHashtable @{logname = 'System'; id = 36880 } | 
    ForEach-Object {
        $date = $_.timecreated
        [xml]$xmlEvent = $_.ToXml()
        $object = $xmlEvent.event.UserData.EventXML
        $object | Add-Member -MemberType NoteProperty -Name TimeCreated -Value $date
        $object
    } | 
    Where-Object { $_.timecreated -gt (Get-Date).Addhours(-1) } |
    Where-Object { ($_.targetname -inotlike '*microsoft*') `
            -and ($_.targetname -inotlike '*msedge.net') } | 
    Where-Object { $_.protocol -eq 'TLS 1.0' } |
    Where-Object { $_.type -eq 'server' } | 
    Select-Object Type, Protocol, TargetName, TimeCreated, '*Cert*Name'
}