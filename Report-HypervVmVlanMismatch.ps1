# Find VMs with a vNIC configured for a VLAN not configured on it's vSwitch

# more info: https://techcommunity.microsoft.com/t5/system-center-blog/fixing-non-compliant-virtual-switches-in-system-center-2012/ba-p/347650
$misconfiguredVMs = "vmm1", "vmm2" | 
ForEach-Object {
    Invoke-Command $_ {
        Import-module VirtualMachineManager
        
        Get-VMMServer $env:COMPUTERNAME | Get-VM | Get-VirtualNetworkAdapter | 
        Where-Object { $_.virtualnetworkadaptercomplianceerrors -ne $null }
    }
}

$properties = 'name', 'vmnetwork', 'virtualnetwork', 'ipv4addresses', 
'defaultipgateways', 'ipv4subnets', 'vlanid', 
'virtualnetworkadaptercomplianceerrors'

$misconfiguredVMs | Select-Object -Property $properties 