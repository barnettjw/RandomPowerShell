# Gets details on checkpoints of VMs from VMM

"vmm1", "vmm2" | ForEach-Object {
    Invoke-Command $_ {
        Import-Module VirtualMachineManager
        Get-VMMServer $env:COMPUTERNAME | Get-VMCheckpoint | 
        Select-Object Name, 
        @{ n = "VM"; Expression = { $_.VM.tostring() } },
        @{ n = "DaysOld"; e = {((Get-Date) - $_.AddedTime).days } },
        @{ n = "TakenBy"; Expression = { $_.CheckpointHWProfile.Owner } },
        AddedTime, Description, 
        @{ n = "VMSizeGB"; e = {
            $disks = $_.VM.VirtualHardDisks
            [math]::Round( ( ( ($disks| Measure-Object Size -sum) ).sum /1GB ),1 )
        } }
    }
}