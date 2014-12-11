# == Class: windows_dhcp
#
# Puppet module to install and configure the Windows DHCP server. Use this class to install and
# configure your DHCP server level options.
#
# === Parameters
#
# [*domain_user*]
#   Domain user used to authorise your DHCP server in Active Directory. For information on how to
#   configure this user please see the README. This is a required parameter.
#
# [*domain_pass*]
#   Password for domain user. This is required parameter.
#
# [*conflictdetectionattempts*]
#   Specifies the number of times that the DHCP server service should attempt conflict detection
#   before leasing an IP address. The acceptable values for this parameter are 0 through 5. The
#   default value is '0'.
#
# [*populate_security_group*]
#   Specifies if the module should populate the "DHCP Administrators" could with the configured
#   $domain_user. This is for organisations that manage local group membership via group policy;
#   setting this option to true will ensure Puppet and the GPO don't fight over group membership.
#
class windows_dhcp (
  $domain_user,
  $domain_pass,
  $conflictdetectionattempts = 0,
  $populate_security_group = true,
) {

  if ! $::osfamily == 'Windows' {
    fail("${::operatingsystem} not supported")
  }

  validate_re($conflictdetectionattempts, '[0-5]', '$conflictdetectionattempts must be between 0 and 5')

  $credentials = "
\$pass = convertto-securestring -String \"${domain_pass}\" -AsPlainText -Force;
\$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist \"${domain_user}\",\$pass
"

  class { '::windows_dhcp::install': } ->
  class { '::windows_dhcp::config': } ~>
  class { '::windows_dhcp::service': } ->
  Class['::windows_dhcp']
}
