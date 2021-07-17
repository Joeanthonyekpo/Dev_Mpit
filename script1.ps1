$ResourceGroupName = "sqlvm1"
$Location = "westus2"
New-AzResourceGroup -Name $ResourceGroupName -Location $Location
$SubnetName = $ResourceGroupName + "subnet"
$VnetName = $ResourceGroupName + "vnet"
$PipName = $ResourceGroupName + $(Get-Random)

# Create a subnet configuration
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix 192.168.1.0/24

# Create a virtual network
$Vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location `
   -Name $VnetName -AddressPrefix 192.168.0.0/16 -Subnet $SubnetConfig

# Create a public IP address and specify a DNS name
$Pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location `
   -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name $PipName
# Rule to allow remote desktop (RDP)
$NsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "RDPRule" -Protocol Tcp `
   -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * `
   -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

#Rule to allow SQL Server connections on port 1433
$NsgRuleSQL = New-AzNetworkSecurityRuleConfig -Name "MSSQLRule"  -Protocol Tcp `
   -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * `
   -DestinationAddressPrefix * -DestinationPortRange 1433 -Access Allow

# Create the network security group
$NsgName = $ResourceGroupName + "nsg"
$Nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName `
   -Location $Location -Name $NsgName `
   -SecurityRules $NsgRuleRDP,$NsgRuleSQL

$InterfaceName = $ResourceGroupName + "int"
$Interface = New-AzNetworkInterface -Name $InterfaceName `
   -ResourceGroupName $ResourceGroupName -Location $Location `
   -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $Pip.Id `
   -NetworkSecurityGroupId $Nsg.Id



Brianjayden@1209
Brianjayden@1209


sqluser01

mstsc /v:40.91.104.73

\\sql02VM\SQLSERVERDB_migrate


  "appId": "3d7a3b01-26eb-44ee-9faf-8b95353ba2ec",
  "displayName": "SPadmin",
  "name": "http://SPadmin",
  "password": "Km3sa8I_IklEW4MDA8~bdYNw7R4dZeY~th",
  "tenant": "c6a9189b-ec93-4466-9d74-644a383572b0"