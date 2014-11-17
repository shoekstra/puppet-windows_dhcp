# == Class windows_dhcp::install
#
class windows_dhcp::install {

  windowsfeature { 'dhcp':
    installmanagementtools =>  true
  }

  exec { "windows_dhcp authorize ${::fqdn}":
    command  => "${windows_dhcp::credentials}; Add-DhcpServerInDC -DnsName \“${::fqdn}\” -credentials $cred",
    unless   => "if ((Get-DhcpServerInDC).DnsName -contains \"${::fqdn}\") { exit 0 } else { exit 1 }",
    provider => 'powershell',
    require  => Windowsfeature['dhcp'],
  }
}
