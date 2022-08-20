function Get-MSSQLInstallation() {
    # parse installed MS SQL instances from registry

    param( )
    
    $db = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' -Recurse -ea SilentlyContinue | 
    ForEach-Object { 
        if ((Get-ItemProperty -Path $_.PsPath -ea SilentlyContinue) -match 'digitalproductid') {
            # parse registry path
            $arr = $($_.PsPath).Split('\')
            $regPath = $arr[1..$arr.Count] -join ('\')

            # only get instances where the database is installed and not just the tools
            Get-ItemProperty $regPath | 
            Where-Object { 
                $_.featurelist -ilike '*SQL_Engine_Core_Inst*' 
            } | Select-Object version, edition
        }
    }
        
    # get hardware details
    $sysmodel = Get-WmiObject –class Win32_ComputerSystem `
        -Property Manufacturer, Model
        
    if ($sysmodel.Model -eq 'Virtual Machine') { $type = 'Virtual' }
    else { $type = 'Physical' }
    
    $os = $(Get-WmiObject -class Win32_OperatingSystem -property caption).caption
    
    # output properties as an object
    [pscustomobject]@{
        'Computer'     = $env:COMPUTERNAME
        'SQL Edition'  = $($db.edition)[0]
        'SQL Version'  = $($db.version)[0]
        'Model'        = $sysmodel.model
        'Manufacturer' = $sysmodel.Manufacturer
        'OS'           = $os
        'Server Type'  = $type
    }
}