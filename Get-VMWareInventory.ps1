function Get-VMWareInventory() {
    # inventory VMWare vCenter VMs

    # Required PowerShell Module: VMware.PowerCLI

    Get-VM | Select-Object Name, PowerState, NumCPU, 
    MemoryGB, CoresPerSocket, Notes,
    @{N = 'IP Address'; E = { @($_.guest.IPAddress[0]) } },
    @{N = 'Hostname'; E = { @($_.guest.HostName) } },
    @{N = 'Guest OS'; E = { @($_.ExtensionData.Guest.GuestId) } },
    @{N = 'ESXi Host'; E = { Get-VMHost -VM $_ } }, 
    @{N = 'Datastore'; E = { Get-Datastore -VM $_ } }, 
    @{N = 'DiskUsedGB'; E = { [math]::round( $_.UsedSpaceGB, 1 ) } },
    @{N = 'DiskSizeGB'; E = { [math]::round( $_.provisionedspacegb, 1 ) } } ,
    @{N = 'ToolsStatus'; E = { $_.ExtensionData.Guest.ToolsStatus } },
    @{N = 'Imported Virtual Appliance'; E = { $null -ne $_.ExtensionData.Config.VAppConfig } },
    @{N = 'ISO Mounted'; E = { $($_ | Get-CDDrive | Where-Object { { $_.isopath -ilike '\[*.iso' } } ).IsoPath | Split-Path -Leaf } 
    }
}