# == Class windows_dhcp::config
#
# This class is called from windows_dhcp
#
class windows_dhcp::config {

  exec { "windows_dhcp add security groups ${::fqdn}":
    command  => "Add-DhcpServerSecurityGroup",
    unless   => "if (((Get-WMIObject Win32_Group -filter {domain=\"${::hostname}\"}).Name | ?{\$_ -match \"DHCP\"}).count -eq 0) { exit 1 }",
    provider => 'powershell',
  } ->

  exec { "windows_dhcp add ${windows_dhcp::domain_user} to \"DHCP Administrators\"":
    command  => "net localgroup \"DHCP Administrators\" /ADD ${windows_dhcp::domain_user}",
    unless   => "if ($(net localgroup \"DHCP Administrators\") -contains \"${windows_dhcp::domain_user}\") { exit 0 } else { exit 1 }",
    provider => 'powershell',
  } ->

  exec { "windows_dhcp authorize ${::fqdn}":
    command  => "${windows_dhcp::credentials}; saps powershell.exe -Credential \$cred -NoNewWindow -ArgumentList \"Add-DhcpServerInDC\"",
    unless   => "if ((Get-DhcpServerInDC).DnsName -contains \"${::fqdn}\") { exit 0 } else { exit 1 }",
    provider => 'powershell',
  }
}
