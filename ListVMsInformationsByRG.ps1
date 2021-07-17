param(
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroup
)
# First you need to install module ImportExcel
# Install-Module ImportExcel -Scope CurrentUser
$ErrorActionPreference = "stop"

#Test if the giver ResourceGroup exist?
try {
    Get-AzResourceGroup -name $ResourceGroup
}
catch {
    Write-Output "Resource group '$ResourceGroup' does not exists! Please enter a valid resource group."
    return
}

Write-Host "Getting All Virtual Machines..."
$WindowsRunningVMs = get-azvm -status -ResourceGroupName $ResourceGroup

$CommonVmsInfo = @()
$DataDisksInfo = @()
$NetworkInterfaceInfo = @()
foreach ($vm in $WindowsRunningVMs) {
    $currentVM = get-azvm -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
    #------------------- Getting VMs Information Details -------------------
    $VMName = $currentVM.Name
    $VMResourceGroupName = $currentVM.ResourceGroupName
    $VMStatus = $vm.PowerState
    $VMSize =  $currentVM.HardwareProfile.VmSize

    $VMComputerName = $currentVM.OSProfile.ComputerName
    $VMAdmineUserName = $currentVM.OSProfile.AdminUsername
   
    $VMOsType = $currentVM.StorageProfile.OsDisk.OsType
    $VMPublisher = $currentVM.StorageProfile.ImageReference.Publisher
    $VMRelease = $currentVM.StorageProfile.ImageReference.sku
    $VMReleaseVersion = $currentVM.StorageProfile.ImageReference.version

    $OsDiskName = $currentVM.StorageProfile.OsDisk.Name
    $OsDiskSizeGB = $currentVM.StorageProfile.OsDisk.DiskSizeGB

    Write-Host "VM Name: $($currentVM.Name)`tStatus: $($vm.PowerState)"
    $CommonVmsInfo_object = New-Object PSObject
    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMName" -Value $VMName
    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMResourceGroupName" -Value $VMResourceGroupName
    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMStatus" -Value $VMStatus
    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMSize" -Value $VMSize

    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMComputerName" -Value $VMComputerName
    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMAdmineUserName" -Value $VMAdmineUserName

    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMOsType" -Value $VMOsType
    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMPublisher" -Value $VMPublisher
    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMRelease" -Value $VMRelease
    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "VMReleaseVersion" -Value $VMReleaseVersion

    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "OsDiskName" -Value $OsDiskName
    $CommonVmsInfo_object | Add-Member -MemberType NoteProperty -Name "OsDiskSizeGB" -Value $OsDiskSizeGB

    $CommonVmsInfo += $CommonVmsInfo_object

    #------------------- Get all data disks -------------------
    foreach ($dataDisk in $currentVM.StorageProfile.DataDisks) {
        $dataDiskName = $dataDisk.Name
        $CurrentDataDisk = Get-AzDisk -ResourceGroupName $currentVM.ResourceGroupName -DiskName $dataDisk.Name
        $dataDisksizeGB = $currentDataDisk.DiskSizeGB
        $dataDiskSku = $currentDataDisk.sku.Name

        Write-Host "VM Name: $($vm.Name)`tDisk Name: $dataDiskName`tSKU: $dataDiskSku" -ForegroundColor Yellow
        $DataDisksInfo_object = New-Object PSObject
        $DataDisksInfo_object | Add-Member -MemberType NoteProperty -Name "Disk Name" -Value $dataDiskName
        $DataDisksInfo_object | Add-Member -MemberType NoteProperty -Name "VM Name" -Value $currentVM.Name
        $DataDisksInfo_object | Add-Member -MemberType NoteProperty -Name "size GB" -Value $dataDisksizeGB
        $DataDisksInfo_object | Add-Member -MemberType NoteProperty -Name "SKU" -Value $dataDiskSku

        $DataDisksInfo += $DataDisksInfo_object
    }


    #------------------- Get all IP Configurations / NIC -------------------
    $VMNetworkInterfaces = $currentVM.NetworkProfile.NetworkInterfaces
    # Check first if there a nic attached to the vm
    if ($null -ne $VMNetworkInterfaces) {
        foreach($nic in $VMNetworkInterfaces) {

            $NicId = $nic.id
            $NicName = $NicId.split('/')[-1]
            $CurrentNic = Get-AzNetworkInterface -Name $NicName -ResourceGroupName $currentVM.ResourceGroupName
            #Getting Public and Private IP Addresses:
            $PrivateIPList = ""
            $PublicIPList = ""
            foreach ($IPConfig in $CurrentNic.IpConfigurations) {
                $PrivateIPList = $PrivateIPList + " " + $IPConfig.PrivateIpAddress
                if ($null -ne $PubIPConfig.PublicIpAddress) {
                    $CurrentPublicIPName = ($IPConfig.PublicIpAddress.Id).split('/')[-1]
                    $CurrentPublicIPRG = ($IPConfig.PublicIpAddress.Id).split('/')[4]
                    $CurrentPublicIP = (Get-AzPublicIpAddress -Name $CurrentPublicIPName -ResourceGroupName $CurrentPublicIPRG).IpAddress
                    $PublicIPList = $PublicIPList + " " + $CurrentPublicIP
                }
                else {
                    $PublicIPList = $PublicIPList + " " + "None"
                }
            }
            if ($true -eq $CurrentNic.EnableAcceleratedNetworking) {
                $AcceleratedNetworking = "Enabled"
            }
            else {
                $AcceleratedNetworking = "Disabled"
            }

            Write-Host "VM Name: $($vm.Name)`tNIC Name: $NicName" -ForegroundColor Yellow
            $NIC_object = New-Object PSObject
            $NIC_object | Add-Member -MemberType NoteProperty -Name "NIC Name" -Value $NicName
            $NIC_object | Add-Member -MemberType NoteProperty -Name "VM Name" -Value $currentVM.Name
            $NIC_object | Add-Member -MemberType NoteProperty -Name "Accelerated Networking" -Value $AcceleratedNetworking
            $NIC_object | Add-Member -MemberType NoteProperty -Name "Private IPs" -Value $PrivateIPList
            $NIC_object | Add-Member -MemberType NoteProperty -Name "Public IPs" -Value $PublicIPList

            $NetworkInterfaceInfo += $NIC_object
        }
    }
    else {
            write-Host "The is no Network Interface Card attached to the vm '$($currentVM.Name)'"
    }
}

$CommonVmsInfo | Export-Excel "VmsInformation.xlsx" -WorksheetName "VMs Common Information"
$DataDisksInfo | Export-Excel "VmsInformation.xlsx" -WorksheetName "Data Disks Information"
$NetworkInterfaceInfo | Export-Excel "VmsInformation.xlsx" -WorksheetName "VMs Network Information"
