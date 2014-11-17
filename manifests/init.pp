# == Class: windows_dhcp
#
# Full description of class windows_dhcp here.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
class windows_dhcp (
  $domain_user,
  $domain_pass,
) {

  # validate parameters here
  if ! $::osfamily == 'Windows' {
    fail("${::operatingsystem} not supported")
  }

  $credentials = "
$pass = convertto-securestring -String \"${domain_pass}\" -AsPlainText -Force;
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist \"${domain_user}\",$pass
"

  class { '::windows_dhcp::install': } ->
  class { '::windows_dhcp::config': } ~>
  class { '::windows_dhcp::service': } ->
  Class['::windows_dhcp']
}
