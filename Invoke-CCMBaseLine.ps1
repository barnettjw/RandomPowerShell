function Invoke-CCMBaseLine {
    param (
        $baseline, 
        $computer, 
        [switch]$machinePolicy, 
        [switch]$userPolicy, 
        [switch]$hardwareInventory, 
        [switch]$softwareInventory, 
        [switch]$getBaselines 
    )

    Invoke-Command $computer {
        if (-not $using:getBaselines) {
            $cpAppletMgr = New-Object -ComObject CPApplet.CPAppletMgr
            if ($using:machinePolicy) { $actionName = 'Request & Evaluate Machine Policy' }
            if ($using:userPolicy) { $actionName = 'Request & Evaluate User Policy' }
            if ($using:hardwareInventory) { $actionName = 'Hardware Inventory Collection Cycle' }
            if ($using:softwareInventory) { $actionName = 'Software Inventory Collection Cycle' }

            $action = $cpAppletMgr.GetClientActions() | 
            Where-Object { $_.Name -match $actionName }
            
            if ($null -ne $action) {
                $action.PerformAction()
                Start-Sleep -Seconds 30
            }
        }
        
        # Evaluate selected baselines
        If ($null -eq $using:baseline) {
            $baselines = Get-WmiObject -Namespace root\ccm\dcm -Class SMS_DesiredConfiguration
        }
        Else {
            $baselines = Get-WmiObject -Namespace root\ccm\dcm -Class SMS_DesiredConfiguration | 
            Where-Object { $_.DisplayName -eq $using:baseline }
        }

        if ($using:getBaselines) {
            $baselines | 
            Select-Object pscomputername, displayname, 
            ismachinetarget, lastcompliancestatus, version 
        }
        else {
            $baselines | ForEach-Object { 
                ([wmiclass]"\\$($env:COMPUTERNAME)\root\ccm\dcm:SMS_DesiredConfiguration").TriggerEvaluation($_.Name, $_.Version)
            }
        }
    }
}