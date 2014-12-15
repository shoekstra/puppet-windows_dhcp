# == Define: windows_dhcp::reservation
#
# Use windows_dhcp::reservation to configure DHCP reservations for IPv4 scopes. This module does
# not yet support IPv6 reservations.
#
# === Parameters
#
# [*description*]
#   Specifies the description of the reservation. This defaults to 'Reservation created by Puppet'.
#
# [*ip_address*]
#   Specifies the IPv4 address you wish to reserver. This is a required parameter.
#
# [*name*]
#   Specifies the name of the reservation.
#
# [*scope_id*]
#   Specifies the IPv4 scope to create the reservation in. This is a required parameter.
#
define windows_dhcp::reservation (
  $ensure = present,
  $ip_address,
  $scope_id,
  $name = undef,
  $description = "Reservation created by Puppet"
) {

  # Scope should be managed by Puppet to ensure it exists before trying to create a reservation.
  if ! defined(Windows_dhcp::Scope[$scope_id]) {
    fail("${scope_id} is not a puppet managed dhcp scope")
  }

  Windows_dhcp::Scope[$scope_id] -> Windows_dhcp::Reservation[$title]

  $mac = upcase(regsubst($title, ':', '-'))

  validate_re($mac, '^([0-9A-F]{2}-){5}([0-9A-F]{2})$',
  'title must be a MAC address written as 6 groups of 2 hexadecimal characters')

  validate_re($ensure, '(present|absent)',
  'ensure must be either present or absent')

  Exec {
    provider => powershell,
    require  => Exec["add ${mac}"],
  }

  if $ensure == 'present' {
    exec { "add ${mac}":
      command => "Add-DhcpServerv4Reservation -Name \"${name}\" -ScopeId ${scope_id} -IPAddress ${ip_address} -ClientId ${mac} -Description \"${description}\"",
      unless  => "if (Get-DhcpServerv4Reservation -ScopeId ${scope_id} -ClientId ${mac}) { exit 0 } else { else 1 }",
      require => undef,
    }

    exec { "set ${mac} description":
      command => "Set-DhcpServerv4Reservation -IPAddress ${ip_address} -Description \"${description}\"",
      unless  => "if ((Get-DhcpServerv4Reservation -ScopeId ${scope_id} -ClientId ${mac}).Description -ne \"${description}\") { exit 1 }"
    }

    exec { "set ${mac} name":
      command => "Set-DhcpServerv4Reservation -IPAddress ${ip_address} -Name \"${name}\"",
      unless  => "if ((Get-DhcpServerv4Reservation -ScopeId ${scope_id} -ClientId ${mac}).Name -ne \"${name}\") { exit 1 }",
    }
  } else {
    exec { "remove ${mac}":
      command => "Remove-DhcpServerv4Reservation -ScopeId ${scope_id} -IPAddress ${ip_address} -ClientId ${mac} -Description \"${description}\"",
      unless  => "if (Get-DhcpServerv4Reservation -ScopeId ${scope_id} -ClientId ${mac}) { exit 1 } else { else 0 }",
      require => undef,
    }
  }
}
