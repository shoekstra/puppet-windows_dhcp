# == Class windows_dhcp::config
#
# This class is called from windows_dhcp, it drives module configuration.
#
class windows_dhcp::config {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  Exec {
    provider => 'powershell',
  }

  exec { 'add DHCP security groups':
    command => "Add-DhcpServerSecurityGroup",
    unless  => "if ($(net localgroup) -contains '*DHCP Administrators') { exit 0 } else { exit 1 }",
    before  => Exec['authorise server']
  }

  if $windows_dhcp::populate_security_group {
    exec { "add ${windows_dhcp::domain_user} to \"DHCP Administrators\"":
      command => "net localgroup \"DHCP Administrators\" /ADD ${windows_dhcp::domain_user}",
      unless  => "if ($(net localgroup \"DHCP Administrators\") -contains \"${windows_dhcp::domain_user}\") { exit 0 } else { exit 1 }",
      require => Exec['add DHCP security groups'],
      before  => Exec['authorise server'],
    }
  }

  exec { 'authorise server':
    command => "${windows_dhcp::credentials}; saps powershell.exe -Credential \$cred -NoNewWindow -ArgumentList \"Add-DhcpServerInDC\"",
    unless  => "if ((Get-DhcpServerInDC).DnsName -contains \"${::fqdn}\") { exit 0 } else { exit 1 }",
  }

  exec { 'set conflict detection attempts':
    command => "Set-DhcpServerSetting -ConflictDetectionAttempts ${windows_dhcp::conflictdetectionattempts}",
    unless  => "if ((Get-DhcpServerSetting).conflictdetectionattempts -ne ${windows_dhcp::conflictdetectionattempts}) { exit 1 }",
  }
}
