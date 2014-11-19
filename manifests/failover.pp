# == Define: windows_dhcp::failover
#
# Use windows_dhcp::failover to configure DHCP failover partnerships.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
define windows_dhcp::failover (
  $partnerserver,
  $subnet,
  $mode = 'loadbalance',
  $autostatetransition = false,
  $loadbalancepercent = 50,
  $maxclientleadtime = '1:00:00',
  $reservepercent = 5,
  $serverrole = 'active',
  $sharedsecret = undef,
  $stateswitchinterval = undef,
) {

  Windows_dhcp::Subnet <| |> -> Windows_dhcp::Failover[$title]

  validate_re($mode, '(loadbalance|hotstandby)')

  if is_array($subnet) {
    $escaped = join(prefix(suffix($subnet,'\''),'\''),',')
    $scopeid = "@(${escaped})"
  } else {
    $scopeid = $subnet
  }

  $common_options = "-AutoStateTransition \$${autostatetransition} -MaxClientLeadTime ${maxclientleadtime} -SharedSecret ${sharedsecret} -StateSwitchInterval ${stateswitchinterval}"

  Exec {
    provider => 'powershell',
    require  => Exec["windows_dhcp failover add ${title}"]
  }

  if $mode == 'loadbalance' {
    $mode_options = "-LoadBalancePercent ${loadbalancepercent}"

    exec { "windows_dhcp failover set ${title} loadbalancepercent":
      command => "Set-DhcpServerv4Failover ${title} -LoadBalancePercent ${loadbalancepercent}",
      unless  => "if ((Get-DhcpServerv4Failover ${title}).LoadBalancePercent -ne ${loadbalancepercent}) { exit 1 }",
    }
  } else {
    $mode_options = "-ReservePercent ${reservepercent} -ServerRole ${serverrole}"

    exec { "windows_dhcp failover set ${title} reservepercent":
      command => "Set-DhcpServerv4Failover ${title} -ReservePercent ${reservepercent}",
      unless  => "if ((Get-DhcpServerv4Failover ${title}).ReservePercent -ne ${reservepercent}) { exit 1 }",
    }
  }

  exec { "windows_dhcp failover add ${title}":
    command => "Add-DhcpServerv4Failover -Name ${title} -ScopeId ${scopeid} -PartnerServer ${partnerserver} ${common_options} ${mode_options} -Force",
    unless  => "if (Get-DhcpServerv4Failover ${title}) { exit 0 } else { exit 1 }",
    require => undef,
  }

  exec { "windows_dhcp failover set ${title} autostatetransition":
    command => "Set-DhcpServerv4Failover ${title} -AutoStateTransition \$${autostatetransition}",
    unless  => "if ((Get-DhcpServerv4Failover ${title}).AutoStateTransition -ne \$${autostatetransition}) { exit 1 }",
  }

  exec { "windows_dhcp failover set ${title} maxclientleadtime":
    command => "Set-DhcpServerv4Failover ${title} -MaxClientLeadTime ${maxclientleadtime}",
    unless  => "if ((Get-DhcpServerv4Failover ${title}).MaxClientLeadTime -ne ${maxclientleadtime}) { exit 1 }",
  }

  exec { "windows_dhcp failover set ${title} mode":
    command => "Set-DhcpServerv4Failover ${title} -Mode ${mode}",
    unless  => "if ((Get-DhcpServerv4Failover ${title}).Mode -ne ${mode}) { exit 1 }",
  }

  exec { "windows_dhcp failover set ${title} stateswitchinterval":
    command => "Set-DhcpServerv4Failover ${title} -StateSwitchInterval ${stateswitchinterval}",
    unless  => "if ((Get-DhcpServerv4Failover ${title}).StateSwitchInterval -ne ${stateswitchinterval}) { exit 1 }",
  }

  # Use a basic powershell script on the file system to keep the failover scopes in sync

  file { 'C:/Windows/Temp/Update-DhcpServerv4FailoverScope.ps1':
    ensure => present,
    source => 'puppet:///modules/windows_dhcp/Update-DhcpServerv4FailoverScope.ps1',
  }

  exec { "windows_dhcp failover set ${title} scopeid":
    command => "C:/Windows/Temp/Update-DhcpServerv4FailoverScope.ps1' -Name ${title} -ScopeId $scopeid",
    unless  => "if ((Compare-Object (Get-DhcpServerv4Failover ${title}).ScopeId ${scopeid}).count -gt 0) { write 1 }",
    require => [Exec["windows_dhcp failover add ${title}"], File['C:/Windows/Temp/Update-DhcpServerv4FailoverScope.ps1']],
  }
}
