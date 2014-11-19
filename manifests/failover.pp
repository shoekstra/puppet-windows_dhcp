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
  $scopeid,
  $mode = 'loadbalance',
  $loadbalancepercent = 50,
  $maxclientleadtime = '1:00:00',
  $reservepercent = 5,
  $serverrole = 'active',
  $sharedsecret = undef,
  $stateswitchinterval = '1:00:00',
) {

  Windows_dhcp::Subnet <| |> -> Windows_dhcp::Failover[$title]

  validate_re($mode, '(loadbalance|hotstandby)')

  if is_array($scopeid) {
    $escaped = join(prefix(suffix($scopeid,'\''),'\''),',')
    $subnets = "@(${escaped})"
  } else {
    $subnets = $scopeid
  }

  if $stateswitchinterval == "0" or $stateswitchinterval == undef { 
    $autostatetransition = false
  } else {
    $autostatetransition = true
  }

  $common_options = "-AutoStateTransition \$${autostatetransition} -MaxClientLeadTime ${maxclientleadtime} -SharedSecret ${sharedsecret} -StateSwitchInterval ${stateswitchinterval}"

  Exec {
    provider => 'powershell',
    require  => Exec["add ${title}"]
  }

  if $mode == 'loadbalance' {
    $mode_options = "-LoadBalancePercent ${loadbalancepercent}"

    exec { "set ${title} loadbalancepercent":
      command => "Set-DhcpServerv4Failover ${title} -LoadBalancePercent ${loadbalancepercent}",
      unless  => "if ((Get-DhcpServerv4Failover ${title}).LoadBalancePercent -ne ${loadbalancepercent}) { exit 1 }",
    }
  } else {
    $mode_options = "-ReservePercent ${reservepercent} -ServerRole ${serverrole}"

    exec { "set ${title} reservepercent":
      command => "Set-DhcpServerv4Failover ${title} -ReservePercent ${reservepercent}",
      unless  => "if ((Get-DhcpServerv4Failover ${title}).ReservePercent -ne ${reservepercent}) { exit 1 }",
    }
  }

  exec { "add ${title}":
    command => "Add-DhcpServerv4Failover -Name ${title} -ScopeId ${subnets} -PartnerServer ${partnerserver} ${common_options} ${mode_options} -Force",
    unless  => "if (Get-DhcpServerv4Failover ${title}) { exit 0 } else { exit 1 }",
    require => undef,
  }

  exec { "set ${title} autostatetransition":
    command => "Set-DhcpServerv4Failover ${title} -AutoStateTransition \$${autostatetransition}",
    unless  => "if ((Get-DhcpServerv4Failover ${title}).AutoStateTransition -ne \$${autostatetransition}) { exit 1 }",
  }

  exec { "set ${title} maxclientleadtime":
    command => "Set-DhcpServerv4Failover ${title} -MaxClientLeadTime ${maxclientleadtime}",
    unless  => "if ((Get-DhcpServerv4Failover ${title}).MaxClientLeadTime -ne \"${maxclientleadtime}\") { exit 1 }",
  }

  exec { "set ${title} mode":
    command => "Set-DhcpServerv4Failover ${title} -Mode ${mode}",
    unless  => "if ((Get-DhcpServerv4Failover ${title}).Mode -ne ${mode}) { exit 1 }",
  }

  exec { "set ${title} stateswitchinterval":
    command => "Set-DhcpServerv4Failover ${title} -StateSwitchInterval ${stateswitchinterval}",
    unless  => "if ((Get-DhcpServerv4Failover ${title}).StateSwitchInterval -ne ${stateswitchinterval}) { exit 1 }",
  }

  # Use a basic powershell script on the file system to keep the failover scopes in sync

  file { 'C:/Windows/Temp/Update-DhcpServerv4FailoverScope.ps1':
    ensure => present,
    source => 'puppet:///modules/windows_dhcp/Update-DhcpServerv4FailoverScope.ps1',
  }

  exec { "set ${title} subnets":
    command => "C:/Windows/Temp/Update-DhcpServerv4FailoverScope.ps1' -Name ${title} -ScopeId $subnets",
    unless  => "if ((Compare-Object (Get-DhcpServerv4Failover ${title}).ScopeId ${subnets}).count -gt 0) { write 1 }",
    require => [Exec["add ${title}"], File['C:/Windows/Temp/Update-DhcpServerv4FailoverScope.ps1']],
  }
}
