# == Define: windows_dhcp::scope
#
# Use the windows_dhcp::scope to configure DHCP scopes.
#
# === Parameters
#
# [*start_range*]
#   Specifies the starting address of the IPv4 range to set for the scope. This is a required
#   parameter.
#
# [*end_range*]
#   Specifies the ending address of the IPv4 range to set for the scope. This is a required
#   parameter.
#
# [*scope_name*]
#   Specifies the name of the scope to create/manage. This is a required parameter.
#
# [*subnet_mask*]
#   Specifies the subnet mask for the scope/network address specified. This is a required
#   parameter.
#
# [*dns_domain*]
#   Specifies the value for the DNS domain option.  The default value is the $::domain fact.
#
# [*dns_server*]
#   Specifies one or more values for the DNS server option, in the IPv4 address format.
#
# [*router*]
#   Specifies one or more values for the router or default gateway option, in IPv4 address format.
#   The default value is undef.
#
# [*activate_policies*]
#   Specifies the enabled state for the policy enforcement on the scope. The acceptable values for
#   this parameter are 'true' or 'false'. The default value is 'true'.
#
# [*delay*]
#   Specifies the time, in milliseconds, by which the DHCP server service should delay sending a
#   response to the clients. This parameter should be used on the secondary DHCP server service in
#   a split scope configuration. The default value is '0'.
#
# [*description*]
#   Specifies the description to set for the scope.
#
# [*lease_duration*]
#   Specifies the duration of the IPv4 address lease to give for the clients of the scope. The
#   default value is '8.00:00:00'.
#
# [*max_bootp_clients*]
#   Specifies the maximum number of BootP clients permitted to get an IP address lease from the
#   scope. This parameter can only be used if the 'type' parameter value is set to 'both'. The
#   default value is '4294967295'.
#
# [*state*]
#   Specifies the state of the scope. The acceptable values for this parameter are 'active' and
#   'inactive'. The default value is 'active'.
#
# [*type*]
#   Specifies the type of the scope. The acceptable values for this parameter are 'dhcp', 'bootp'
#   and 'both'. The type of the scope determines if the DHCP server service responds to only DHCP
#   client requests, only BootP client requests, or Both types of clients. The default value is
#   'dhcp'.
#
define windows_dhcp::scope (
  $start_range,
  $end_range,
  $scope_name,
  $subnet_mask,
  $dns_domain = $::domain,
  $dns_server = undef,
  $router = undef,
  $activate_policies = true,
  $delay = 0,
  $description = undef,
  $lease_duration = '8.00:00:00',
  $max_bootp_clients = 4294967295,
  $state = 'active',
  $type = 'dhcp'
) {

  $scope_id = $title

  require windows_dhcp

  validate_re($state, '(active|inactive)')
  validate_re($type, '(bootp|dhcp|both)')

  $options = "-EndRange ${end_range} -StartRange ${start_range} -SubnetMask ${subnet_mask} -Name ${scope_name} -Description \"${description}\" -ActivatePolicies \$${activate_policies} -Delay ${delay} -LeaseDuration ${lease_duration} -MaxBootpClients ${max_bootp_clients} -State ${state} -Type ${type}"

  Exec {
    provider => 'powershell',
    require  => Exec["add ${scope_id}"]
  }

  exec { "add ${scope_id}":
    command => "Add-DhcpServerv4Scope ${options}",
    unless  => "if (Get-DhcpServerv4Scope ${scope_id}) { exit 0 } else { exit 1 }",
    require => undef,
  }

  exec { "set ${scope_id} end range":
    command => "Set-DhcpServerv4Scope ${scope_id} -EndRange ${end_range}",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).EndRange.IPAddressToString -ne \"${end_range}\") { exit 1 }",
  }

  exec { "set ${scope_id} start range":
    command => "Set-DhcpServerv4Scope ${scope_id} -StartRange ${start_range}",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).StartRange.IPAddressToString -ne \"${start_range}\") { exit 1 }",
  }

  exec { "set ${scope_id} name":
    command => "Set-DhcpServerv4Scope ${scope_id} -Name \"${scope_name}\"",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).Name -ne \"${scope_name}\") { exit 1 }",
  }

  exec { "set ${scope_id} activate_policies":
    command => "Set-DhcpServerv4Scope ${scope_id} -ActivatePolicies \$${activate_policies}",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).ActivatePolicies -ne \$${activate_policies}) { exit 1 }",
  }

  exec { "set ${scope_id} delay":
    command => "Set-DhcpServerv4Scope ${scope_id} -Delay ${delay}",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).Delay -ne \"${delay}\") { exit 1 }",
  }

  exec { "set ${scope_id} description":
    command => "Set-DhcpServerv4Scope ${scope_id} -Description \"${description}\"",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).Description -ne \"${description}\") { exit 1 }",
  }

  exec { "set ${scope_id} lease_duration":
    command => "Set-DhcpServerv4Scope ${scope_id} -LeaseDuration ${lease_duration}",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).LeaseDuration -ne \"${lease_duration}\") { exit 1 }",
  }

  exec { "set ${scope_id} max_bootp_clients":
    command => "Set-DhcpServerv4Scope ${scope_id} -MaxBootpClients ${max_bootp_clients}",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).MaxBootpClients -ne \"${max_bootp_clients}\") { exit 1 }",
  }

  exec { "set ${scope_id} state":
    command => "Set-DhcpServerv4Scope ${scope_id} -State ${state}",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).State -ne \"${state}\") { exit 1 }",
  }

  exec { "set ${scope_id} type":
    command => "Set-DhcpServerv4Scope ${scope_id} -Type ${type}",
    unless  => "if ((Get-DhcpServerv4Scope ${scope_id}).Type -ne \"${type}\") { exit 1 }",
  }

  if $dns_domain {
    exec { "set ${scope_id} dns domain":
      command => "Set-DhcpServerv4OptionValue ${scope_id} -DnsDomain ${dns_domain}",
      unless  => "if ((Get-DhcpServerv4OptionValue -ScopeId ${scope_id} -OptionId 15).value -ne \"${dns_domain}\") { exit 1 }",
    }
  }

  if $dns_server {
    if is_array($dns_server) {
      $escaped = join(prefix(suffix($dns_server,'\''),'\''),',')
      $dns = "@(${escaped})"
    } else {
      $dns = $dns_server
    }

    exec { "set ${scope_id} dns server":
      command => "Set-DhcpServerv4OptionValue ${scope_id} -DnsServer ${dns}",
      unless  => "if ((Compare-Object (Get-DhcpServerv4OptionValue -ScopeId ${scope_id} -OptionId 6).value ${dns}).count -gt 0) { exit 1 }",
    }
  }

  if $router {
    exec { "set ${scope_id} router":
      command => "Set-DhcpServerv4OptionValue ${scope_id} -Router ${router}",
      unless  => "if ((Get-DhcpServerv4OptionValue -ScopeId ${scope_id} -OptionId 3).value -ne \"${router}\") { exit 1 }",
    }
  }
}
