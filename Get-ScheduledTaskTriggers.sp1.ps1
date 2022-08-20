# get state triggers of a scheduled task via powershell

$taskName = 'MyTask'
$taskPath = '\Tasks\'

$TaskXML = [XML]((Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath) | 
    Export-ScheduledTask)

$eventTriggers = $TaskXML.Task.Triggers.EventTrigger | 
Where-Object { $_.enabled -eq $true }

$bootTrigger = $TaskXML.Task.Triggers.BootTrigger | 
Where-Object { $_.enabled -eq $true }

$logonTrigger = $TaskXML.Task.Triggers.LogonTrigger | 
Where-Object { $_.enabled -eq $true }

$stateTriggers = $TaskXML.Task.Triggers.SessionStateChangeTrigger | 
Where-Object { $_.enabled -eq $true }

[pscustomobject]@{
    eventTriggers = $($eventTriggers | Measure-Object).Count
    stateTriggers = $($stateTriggers | Measure-Object).Count
    logonTrigger  = $($logonTrigger | Measure-Object).Count
    bootTrigger   = $($bootTrigger | Measure-Object).Count
}