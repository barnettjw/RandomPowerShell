
function Get-AzVmInventory() {

    # inventory Azure VMs

    # Required PowerShell Module: Az.Compute

    [CmdletBinding()]param()

    $vmSizeList = Get-AzVmSizeDetails -verbose

    function Get-AzVmSizeDetails() {
        # get azure VM sizes for each region
        [CmdletBinding()]param()

        $vmSizeList = @{}
        Write-Verbose 'Getting Azure VM Size Details'
        Get-AzVM | Select-Object location -Unique | ForEach-Object {
            $list = Get-AzVMSize -Location $_.Location 
            $vmSizeList.add( $_.Location, $list )
        }

        $vmSizeList
    }

    $i = 0
    $count = $(Get-AzVM | Measure-Object).Count
    $stopswatch = [system.diagnostics.stopwatch]::new()
    Write-Verbose "Getting Azure VMs. Count: $count"
    $stopswatch.Start()

    Get-AzVM -Status | ForEach-Object {
        Write-Progress -Activity "Getting VM: $($_.name)" `
            -Status $('{0:P0}' -f ($i / $count)) `
            -CurrentOperation $('{0:mm\:ss}' -f ([TimeSpan]$stopswatch.Elapsed) ) `
            -PercentComplete (($i / $count) * 100)

        # get memory and cores allocated for VM Size for deployed region
        $size = $_.HardwareProfile.VmSize
        $currentVMSizeList = $vmSizeList[$_.Location]
        $memory = ($currentVMSizeList | Where-Object { $_.name -eq $size }).MemoryInMb
        $cores = ($currentVMSizeList | Where-Object { $_.name -eq $size }).NumberOfCores
    
        [PSCustomObject]@{
            Name              = $_.Name
            HostName          = $_.OSProfile.ComputerName
            GuestOS           = $_.StorageProfile.ImageReference.OSName
            ResourceGroupName = $_.ResourceGroupName
            Location          = $_.Location
            IPAddress         = (Get-AzNetworkInterface -Name $_.NetworkProfile.NetworkInterfaces.Id.Split('/')[-1]).IpConfigurations.PrivateIpAddress
            PublicIPAddress   = (Get-AzPublicIpAddress -Name "$($_.Name)*").IpAddress
            MemoryGB          = ($memory / 1024)
            NumCPU            = $cores
            DiskSizeGB        = $_.StorageProfile.OsDisk.DiskSizeGB
            VMPublisher       = $_.StorageProfile.ImageReference.Publisher
            BuildNUmber       = $_.StorageProfile.ImageReference.ExactVersion
            PowerState        = $_.PowerState
        }

        $i++
    }
}
