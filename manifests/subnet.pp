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
  $activatepolicies = true,
  $delay = 0,
  $description = undef,
  $leaseduration = '8.00:00:00',
  $maxbootpclients = 4294967295,
  $state = 'active',
  $superscopename = undef,
  $type = 'dhcp'
) {

  validate_re($state, '(active|inactive)')
  validate_re($type, '(bootp|dhcp|both)')

  if ! $::osfamily == 'Windows' {
    fail("${::operatingsystem} not supported")
  }

  $options = "-EndRange ${endrange} -StartRange ${startrange} -SubnetMask ${subnetmask} -Name ${title} -Description \"${description}\" -ActivatePolicies \$${activatepolicies} -Delay ${delay} -LeaseDuration ${leaseduration} -MaxBootpClients ${maxbootpclients} -State ${state} -Type ${type} -SuperscopeName ${superscopename}"

  exec { "windows_dhcp add ${title}":
    command  => "Add-DhcpServerv4Scope -Name ${title} ${options}",
    unless   => "if ((Get-DhcpServerv4Scope ${subnet}) { exit 0 } else { exit 1 }",
    require  => undef,
  }

  Exec {
    provider => 'powershell',
    require  => Exec["windows_dhcp add ${title}"]
  }

  exec { "windows_dhcp set ${title} end range":
    command  => "Set-DhcpServerv4Scope ${subnet} -EndRange ${endrange}",
    unless   => "if ((Get-DhcpServerv4Scope ${subnet}).endrange.IPAddressToString -ne \"${endrange}\") { exit 1 }",
  } ->

  exec { "windows_dhcp set ${title} start range":
    command  => "Set-DhcpServerv4Scope ${subnet} -StartRange ${startrange}",
    unless   => "if ((Get-DhcpServerv4Scope ${subnet}).startrange.IPAddressToString -ne \"${startrange}\") { exit 1 }",
  } ->

  exec { "windows_dhcp set ${title} activatepolicies":
    command  => "Set-DhcpServerv4Scope ${subnet} -ActivatePolicies ${activatepolicies}",
    unless   => "Get-DhcpServerv4Scope ${subnet} -ActivatePolicies ${activatepolicies}",
  } ->

  exec { "windows_dhcp set ${title} delay":
    command  => "Set-DhcpServerv4Scope ${subnet} -Delay ${delay}",
    unless   => "if ((Get-DhcpServerv4Scope ${subnet}).delay -ne \"${delay}\") { exit 1 }",
  } ->

  exec { "windows_dhcp set ${title} description":
    command  => "Set-DhcpServerv4Scope ${subnet} -description ${description}",
    unless   => "if ((Get-DhcpServerv4Scope ${subnet}).description -ne \"${description}\") { exit 1 }",
  } ->

  exec { "windows_dhcp set ${title} leaseduration":
    command  => "Set-DhcpServerv4Scope ${subnet} -LeaseDuration ${leaseduration}",
    unless   => "Get-DhcpServerv4Scope ${subnet} -LeaseDuration ${leaseduration}",
  } ->

  exec { "windows_dhcp set ${title} maxbootpclients":
    command  => "Set-DhcpServerv4Scope ${subnet} -maxbootpclients ${maxbootpclients}",
    unless   => "if ((Get-DhcpServerv4Scope ${subnet}).maxbootpclients -ne \"${maxbootpclients}\") { exit 1 }",
  } ->

  exec { "windows_dhcp set ${title} state":
    command  => "Set-DhcpServerv4Scope ${subnet} -state ${state}",
    unless   => "if ((Get-DhcpServerv4Scope ${subnet}).state -ne \"${state}\") { exit 1 }",
  } ->

  exec { "windows_dhcp set ${title} superscopename":
    command  => "Set-DhcpServerv4Scope ${subnet} -superscopename ${superscopename}",
    unless   => "if ((Get-DhcpServerv4Scope ${subnet}).superscopename -ne \"${superscopename}\") { exit 1 }",
  } ->

  exec { "windows_dhcp set ${title} type":
    command  => "Set-DhcpServerv4Scope ${subnet} -Type ${type}",
    unless   => "if ((Get-DhcpServerv4Scope ${subnet}).type -ne \"${type}\") { exit 1 }",
  }
}
