$sw_name = Read-Host -Prompt "Enter switch name:"
New-VMSwitch -SwitchName "$sw_name" -SwitchType Internal 
$if_index = Get-NetAdapter | Select-Object name, ifIndex | Select-String $sw_name ; $if_number = $if_index -replace "\D" , ""
$ip_add = Read-Host -Prompt "Enter IP address:"
$prefix_length = Read-Host -Prompt "Enter the prefix length"
New-NetIPAddress -IPAddress $ip_add -PrefixLength $prefix_length -InterfaceIndex $if_number
$internal_ip = Read-Host -Prompt "Enter the ip subnet with mask like x.x.x.0/24"
$nat = Read-Host -Prompt "Enter the new Nat name:"
New-NetNat -Name $nat -InternalIPInterfaceAddressPrefix $internal_ip