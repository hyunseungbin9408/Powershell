# $TriggerMetadata is optional here. If you don't need it, you can safely remove it from the param block
param($VirtualMachineName, $TriggerMetadata)
try
{   
    
    $GetAzVM = Get-AzVM -Name $VirtualMachineName
    $GetAzSize = Get-AzVMSize -location $GetAzVm.Location
    if ($GetAzVM.HardwareProfile.VmSize.Substring(0,11) -eq "Standard_DS")
    {
        if ($GetAzVM.HardwareProfile.VmSize.Substring(0,14) -like "Standard_DS*-")
        {
            $GetAzVmSize = $GetAzSize | Where-Object {$_.Name -like "Standard_DS*-*_v*"}
        }
        elseif($GetAzVM.HardwareProfile.VmSize.Substring(0,15) -like "Standard_DS*_v*")
        {
            $GetAzVmSize = $GetAzSize | Where-Object {$_.Name -like "Standard_DS*_v*"} | Where-Object {$_.Name.Length -eq 15}
        }
        else {
            $GetAzVmSize = $GetAzSize | Where-Object {$_.Name -like "$($GetAzVM.HardwareProfile.VmSize.Substring(0,11))*"} | Where-Object {$_.Name -notlike "Standard_DS*-*_v*"}  | Where-Object {$_.Name.Length -eq 16}
        }

    }
    elseif($GetAzVM.HardwareProfile.VmSize.Substring(0,10) -eq "Standard_B")
    {
        $GetAzVmSize = $GetAzSize | Where-Object {$_.Name -like "$($GetAzVM.HardwareProfile.VmSize.Substring(0,10))*"} 
        if ("ms" -like "*$($GetAzVM.HardwareProfile.VmSize.Substring($GetAzVM.HardwareProfile.VmSize.Length-2,2))")
        {
            $GetAzVmSize = $GetAzVmSize | Where-Object {$_.Name -like "*ms"}
        }
        else{
            $GetAzVmSize = $GetAzVmSize | Where-Object {$_.Name -notlike "*ms"}
        }
    }
    else {
        $GetAzVmSize = $GetAzSize | Where-Object {$_.Name -like "$($GetAzVM.HardwareProfile.VmSize.Substring(0,10))*"}
    }
    $vmindex = 0
    for ( $index = 0; $index -lt $GetAzVmSize.count; $index++)
    {
        if($GetAzVmSize.Name[$index] -eq $GetAzVM.HardwareProfile.VmSize)
        {
            $vmindex = $index
        }
    }
    if ($null -notlike $GetAzVM)
    {
        try{
                Write-Output "$($GetAzVM.Name) Start ScaleUp"
                $BeginSize = $GetAzVM.HardwareProfile.VmSize

                $GetAzVM.HardwareProfile.VmSize = ([System.String[]] @($GetAzVmSize.Name[$vmindex+1]))
                $VMUpdate = Update-AzVM -VM $GetAzVM -ResourceGroupName $GetAzVM.ResourceGroupName
            }
            catch{
            }
    }
    else {
        Write-Output "The virtual machine name is invalid or does not exist"
    }
    $GetAzVMSize = Get-AzVM -Name $VirtualMachineName
    if ($GetAzVMSize.HardwareProfile.VmSize -eq $GetAzVM.HardwareProfile.VmSize)
    {
        Write-Output "$($GetAzVM.Name) ($($BeginSize) -> $($GetAzVM.HardwareProfile.VmSize)) Sclae Up Complete"
    }
    else {
        Write-Output "Size-up is not possible for this virtual machine."
    }
    
}
catch {
}
