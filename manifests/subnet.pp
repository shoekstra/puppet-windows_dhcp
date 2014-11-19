# == Define: windows_dhcp::subnet
#
# Use the windows_dhcp::subnet to configure DHCP scopes.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
define windows_dhcp::subnet (
  $startrange,
  $endrange,
  $subnet,
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
    require  => Exec["windows_dhcp subnet add ${title}"]
  }

  exec { "windows_dhcp subnet add ${title}":
    command => "Add-DhcpServerv4Scope ${options}",
    unless  => "if (Get-DhcpServerv4Scope ${subnet}) { exit 0 } else { exit 1 }",
    require => undef,
  }

  exec { "windows_dhcp subnet set ${title} end range":
    command => "Set-DhcpServerv4Scope ${subnet} -EndRange ${endrange}",
    unless  => "if ((Get-DhcpServerv4Scope ${subnet}).endrange.IPAddressToString -ne \"${endrange}\") { exit 1 }",
  }

  exec { "windows_dhcp subnet set ${title} start range":
    command => "Set-DhcpServerv4Scope ${subnet} -StartRange ${startrange}",
    unless  => "if ((Get-DhcpServerv4Scope ${subnet}).startrange.IPAddressToString -ne \"${startrange}\") { exit 1 }",
  }

  exec { "windows_dhcp subnet set ${title} activatepolicies":
    command => "Set-DhcpServerv4Scope ${subnet} -ActivatePolicies \$${activatepolicies}",
    unless  => "if ((Get-DhcpServerv4Scope ${subnet}).ActivatePolicies -ne \$${activatepolicies}) { exit 1 }",
  }

  exec { "windows_dhcp subnet set ${title} delay":
    command => "Set-DhcpServerv4Scope ${subnet} -Delay ${delay}",
    unless  => "if ((Get-DhcpServerv4Scope ${subnet}).delay -ne \"${delay}\") { exit 1 }",
  }

  exec { "windows_dhcp subnet set ${title} description":
    command => "Set-DhcpServerv4Scope ${subnet} -description ${description}",
    unless  => "if ((Get-DhcpServerv4Scope ${subnet}).description -ne \"${description}\") { exit 1 }",
  }

  exec { "windows_dhcp subnet set ${title} leaseduration":
    command => "Set-DhcpServerv4Scope ${subnet} -LeaseDuration ${leaseduration}",
    unless  => "if ((Get-DhcpServerv4Scope ${subnet}).leaseduration -ne \"${leaseduration}\") { exit 1 }",
  }

  exec { "windows_dhcp subnet set ${title} maxbootpclients":
    command => "Set-DhcpServerv4Scope ${subnet} -maxbootpclients ${maxbootpclients}",
    unless  => "if ((Get-DhcpServerv4Scope ${subnet}).maxbootpclients -ne \"${maxbootpclients}\") { exit 1 }",
  }

  exec { "windows_dhcp subnet set ${title} state":
    command => "Set-DhcpServerv4Scope ${subnet} -state ${state}",
    unless  => "if ((Get-DhcpServerv4Scope ${subnet}).state -ne \"${state}\") { exit 1 }",
  }

  exec { "windows_dhcp subnet set ${title} type":
    command => "Set-DhcpServerv4Scope ${subnet} -Type ${type}",
    unless  => "if ((Get-DhcpServerv4Scope ${subnet}).type -ne \"${type}\") { exit 1 }",
  }

  if $dnsdomain {
    exec { "windows_dhcp subnet set ${title} dns domain":
      command => "Set-DhcpServerv4OptionValue ${subnet} -DnsDomain ${dnsdomain}",
      unless  => "if ((Get-DhcpServerv4OptionValue -ScopeId ${subnet} -OptionId 15).value-ne \"${dnsdomain}\") { exit 1 }",
    }
  }

  if $dnsserver {
    if is_array($dnsserver) {
      $escaped = join(prefix(suffix($dnsserver,'\''),'\''),',')
      $dns = "@(${escaped})"
    } else {
      $dns = $dnsserver
    }

    exec { "windows_dhcp subnet set ${title} dns server":
      command => "Set-DhcpServerv4OptionValue ${subnet} -DnsServer ${dns}",
      unless  => "if ((Compare-Object (Get-DhcpServerv4OptionValue -ScopeId ${subnet} -OptionId 6).value ${dns}).count -gt 0) { exit 1 }",
    }
  }

  if $router {
    exec { "windows_dhcp subnet set ${title} router":
      command => "Set-DhcpServerv4OptionValue ${subnet} -Router ${router}",
      unless  => "if ((Get-DhcpServerv4OptionValue -ScopeId ${subnet} -OptionId 3).value-ne \"${router}\") { exit 1 }",
    }
  }
}
