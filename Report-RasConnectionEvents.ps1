# get RAS connection events from event logs

$Filter = @{
    Logname   = 'Application'
    ID        = @(20223, 20225, 20226, 20227)
    StartTime = [datetime]::Now.AddDays(-30)
    EndTime   = [datetime]::Now
}

$events = Get-WinEvent -FilterHashtable $Filter | ForEach-Object {
    [xml]$xmlEvent = $_.ToXml()
    $eventData = $($xmlEvent.event.eventdata.Data)

    [pscustomobject]@{
        Time      = $_.timecreated
        Id        = $_.id
        EventData = $eventData
    }
} | Select-Object -First 1000

#region - 20223 = connected (user, server ip)
$events | Where-Object { $_.id -eq 20223 } | ForEach-Object {
    $object = $_
    $object | Add-Member -MemberType NoteProperty -Name User -Value $_.eventData[1] -Force
        
    $connectionDetails = $($_.eventData[2]).Trim().split("`n")
    $connectionDetails | ForEach-Object {
        $data = $_.split('=').trim()
        $object | Add-Member -MemberType NoteProperty -Name $data[0] -Value $data[1] -Force
    }

    $serverIP = $object.'Server address/Phone Number'


    $coid = $($_.eventData[0]).Trim()
        
    $object | Select-Object -Property Time, Id, User, 
    @{n = 'Connection'; e = { $_.Device } }, @{n = 'IP'; e = { $serverIP } }, 
    ErrorCode, @{n = 'CoId'; e = { $coid } }
}
#endregion

#region - 20225 = connected (user, connection, client ip)
$events | Where-Object { $_.id -eq 20225 } | ForEach-Object {
    $object = $_
    $object | Add-Member -MemberType NoteProperty -Name User -Value $_.eventData[1] -Force
    $object | Add-Member -MemberType NoteProperty -Name Connection -Value $_.eventData[2] -Force
        
    $connectionDetails = $($_.eventData[3]).Trim().split("`n")
    $connectionDetails | ForEach-Object {
        $data = $_.split('=').trim()
        $object | Add-Member -MemberType NoteProperty -Name $data[0] -Value $data[1] -Force
    }

    $object | Select-Object -Last 1 -Property time, id, user, 
    connection, @{n = 'IP'; e = { $_.'TunnelIpAddress' } }, 
    ErrorCode, @{n = 'Message'; e = { 'Connection Successful' } }
}
#endregion

#region - 20226/7 = connection termination reason, error creating connection (user, connection, error code)
$events | Where-Object { ($_.id -eq 20226) -or ($_.id -eq 20227) } | ForEach-Object {
    $object = $_

    $object | Add-Member -MemberType NoteProperty -Name User -Value $_.eventData[1] -Force
    $object | Add-Member -MemberType NoteProperty -Name Connection -Value $_.eventData[2] -Force
    $object | Add-Member -MemberType NoteProperty -Name ErrorCode -Value $_.eventData[3] -Force
        
    $object | Select-Object -Property time, id, user, connection, ip, ErrorCode, @{n = 'Message'; e = { 'Connection Failed' } }
}
#endregion