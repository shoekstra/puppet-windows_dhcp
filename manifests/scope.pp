# == Define: windows_dhcp::scope
#
# Use the windows_dhcp::scope to configure DHCP scopes.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
# [*startrange*]
#   Specifies the starting address of the IPv4 range to set for the scope. This is a required
#   parameter.
#
# [*endrange*]
#   Specifies the ending address of the IPv4 range to set for the scope. This is a required
#   parameter.

# [*scopeid*]
#   Specifies the scope identifier (network address) for the scope specified. This is a required
#   parameter.
#
# [*subnetmask*]
#   Specifies the subnet mask for the scope/network address specified. This is a required
#   parameter.
#
# [*dnsdomain*]
#   Specifies the value for the DNS domain option.  The default value is the $::domain fact.
#
# [*dnsserver*]
#   Specifies one or more values for the DNS server option, in the IPv4 address format.
#
# [*router*]
#   Specifies one or more values for the router or default gateway option, in IPv4 address format.
#   The default value is undef.
#
# [*activatepolicies*]
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
# [*leaseduration*]
#   Specifies the duration of the IPv4 address lease to give for the clients of the scope. The
#   default value is '8.00:00:00'.
#
# [*maxbootpclients*]
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
  $startrange,
  $endrange,
  $scopeid,
  $subnetmask,
  $dnsdomain = $::domain,
  $dnsserver = undef,
  $router = undef,
  $activatepolicies = true,
  $delay = 0,
  $description = undef,
  $leaseduration = '8.00:00:00',
  $maxbootpclients = 4294967295,
  $state = 'active',
  $type = 'dhcp'
) {

  require windows_dhcp

  validate_re($state, '(active|inactive)')
  validate_re($type, '(bootp|dhcp|both)')

  $options = "-EndRange ${endrange} -StartRange ${startrange} -SubnetMask ${subnetmask} -Name ${title} -Description \"${description}\" -ActivatePolicies \$${activatepolicies} -Delay ${delay} -LeaseDuration ${leaseduration} -MaxBootpClients ${maxbootpclients} -State ${state} -Type ${type}"

  Exec {
    provider => 'powershell',
    require  => Exec["add ${title}"]
  }

  exec { "add ${title}":
    command => "Add-DhcpServerv4Scope ${options}",
    unless  => "if (Get-DhcpServerv4Scope ${scopeid}) { exit 0 } else { exit 1 }",
    require => undef,
  }

  exec { "set ${title} end range":
    command => "Set-DhcpServerv4Scope ${scopeid} -EndRange ${endrange}",
    unless  => "if ((Get-DhcpServerv4Scope ${scopeid}).endrange.IPAddressToString -ne \"${endrange}\") { exit 1 }",
  }

  exec { "set ${title} start range":
    command => "Set-DhcpServerv4Scope ${scopeid} -StartRange ${startrange}",
    unless  => "if ((Get-DhcpServerv4Scope ${scopeid}).startrange.IPAddressToString -ne \"${startrange}\") { exit 1 }",
  }

  exec { "set ${title} activatepolicies":
    command => "Set-DhcpServerv4Scope ${scopeid} -ActivatePolicies \$${activatepolicies}",
    unless  => "if ((Get-DhcpServerv4Scope ${scopeid}).ActivatePolicies -ne \$${activatepolicies}) { exit 1 }",
  }

  exec { "set ${title} delay":
    command => "Set-DhcpServerv4Scope ${scopeid} -Delay ${delay}",
    unless  => "if ((Get-DhcpServerv4Scope ${scopeid}).delay -ne \"${delay}\") { exit 1 }",
  }

  exec { "set ${title} description":
    command => "Set-DhcpServerv4Scope ${scopeid} -description ${description}",
    unless  => "if ((Get-DhcpServerv4Scope ${scopeid}).description -ne \"${description}\") { exit 1 }",
  }

  exec { "set ${title} leaseduration":
    command => "Set-DhcpServerv4Scope ${scopeid} -LeaseDuration ${leaseduration}",
    unless  => "if ((Get-DhcpServerv4Scope ${scopeid}).leaseduration -ne \"${leaseduration}\") { exit 1 }",
  }

  exec { "set ${title} maxbootpclients":
    command => "Set-DhcpServerv4Scope ${scopeid} -maxbootpclients ${maxbootpclients}",
    unless  => "if ((Get-DhcpServerv4Scope ${scopeid}).maxbootpclients -ne \"${maxbootpclients}\") { exit 1 }",
  }

  exec { "set ${title} state":
    command => "Set-DhcpServerv4Scope ${scopeid} -state ${state}",
    unless  => "if ((Get-DhcpServerv4Scope ${scopeid}).state -ne \"${state}\") { exit 1 }",
  }

  exec { "set ${title} type":
    command => "Set-DhcpServerv4Scope ${scopeid} -Type ${type}",
    unless  => "if ((Get-DhcpServerv4Scope ${scopeid}).type -ne \"${type}\") { exit 1 }",
  }

  if $dnsdomain {
    exec { "set ${title} dns domain":
      command => "Set-DhcpServerv4OptionValue ${scopeid} -DnsDomain ${dnsdomain}",
      unless  => "if ((Get-DhcpServerv4OptionValue -ScopeId ${scopeid} -OptionId 15).value-ne \"${dnsdomain}\") { exit 1 }",
    }
  }

  if $dnsserver {
    if is_array($dnsserver) {
      $escaped = join(prefix(suffix($dnsserver,'\''),'\''),',')
      $dns = "@(${escaped})"
    } else {
      $dns = $dnsserver
    }

    exec { "set ${title} dns server":
      command => "Set-DhcpServerv4OptionValue ${scopeid} -DnsServer ${dns}",
      unless  => "if ((Compare-Object (Get-DhcpServerv4OptionValue -ScopeId ${scopeid} -OptionId 6).value ${dns}).count -gt 0) { exit 1 }",
    }
  }

  if $router {
    exec { "set ${title} router":
      command => "Set-DhcpServerv4OptionValue ${scopeid} -Router ${router}",
      unless  => "if ((Get-DhcpServerv4OptionValue -ScopeId ${scopeid} -OptionId 3).value-ne \"${router}\") { exit 1 }",
    }
  }
}
