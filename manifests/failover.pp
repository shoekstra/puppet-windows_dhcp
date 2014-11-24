# == Define: windows_dhcp::failover
#
# Use windows_dhcp::failover to configure DHCP failover partnerships for IPv4 scopes. This module
# does not yet support IPv6 failover partnerships.
#
# === Parameters
#
# [*partnerserver*]
#   Specifies the IPv4 address, or host name, of the partner DHCP server with which the failover
#   relationship is created. This is a required parameter.
#
# [*scopeid*]
#   Specifies the scope identifiers, in IPv4 address format, which are to be added to the failover
#   relationship. This is a required parameter.
#
# [*mode*]
#   Specifies a mode for the failover relationship. The acceptable values for this parameter are
#   'hotstandby' and 'loadbalance'. The default value is 'loadbalance'.
#
# [*loadbalancepercent*]
#   Specifies the percentage of DHCP client requests which should be served by the DHCP server. The
#   remaining requests would be served by the partner server service. The default value is '50'.
#
# [*maxclientleadtime*]
#   Specifies the maximum client lead time for the failover relationship. The default value is
#   '1:00:00'.
#
# [*reservepercent*]
#   Specifies the percentage of free IPv4 addresses in the IPv4 address pool of the scope which
#   should be reserved on the standby DHCP server when configured as a hot-standby. In the case of
#   a failover, the IPv4 address from this reserved pool on the standby DHCP server service will be
#   leased to new DHCP clients. The default value is '5'.
#
# [*serverrole*]
#   Specifies the role of the local DHCP server service in hot-standby mode. Acceptable values for
#   this parameter are 'active' or 'standby'. The default value is 'active' for the local DHCP server,
#   such as the partner DHCP server that is specified will be a standby DHCP server. The default
#   value is 'active'.
#
# [*sharedsecret*]
#   Specifies the shared secret to be used for message digest authentication. If not specified,
#   then the message digest authentication is turned off. This is only used when creating the
#   failover partnerships; changing this after a partnership has been created will not update the
#   shared secret. To do change the shared secret you will need to use the MMC.
#
# [*stateswitchinterval*]
#   Specifies the time interval for which the DHCP server operates in the COMMUNICATION INTERRUPTED
#   state before transitioning to the PARTNER DOWN state. Set to '0' to disable.  The default value
#   is '1:00:00'.
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

  Windows_dhcp::Scope <| |> -> Windows_dhcp::Failover[$title]

  validate_re($mode, '(loadbalance|hotstandby)', '$mode must be either loadbalance or hotstandby')
  validate_re($serverrole, '(active|standby)', '$serverrole must be either active or standby')

  if is_array($scopeid) {
    $escaped = join(prefix(suffix($scopeid,'\''),'\''),',')
    $subnets = "@(${escaped})"
  } else {
    $subnets = $scopeid
  }

  if $stateswitchinterval == "0" or $stateswitchinterval == undef {
    $autostatetransition = '$false'
  } else {
    $autostatetransition = '$true'
  }

  $common_options = "-AutoStateTransition ${autostatetransition} -MaxClientLeadTime ${maxclientleadtime} -SharedSecret \"${sharedsecret}\" -StateSwitchInterval ${stateswitchinterval}"

  Exec {
    provider => 'powershell',
    require  => Exec["add ${title}"]
  }

  if $mode == 'loadbalance' {
    $mode_options = "-LoadBalancePercent ${loadbalancepercent}"

    exec { "set ${title} loadbalancepercent":
      command => "Set-DhcpServerv4Failover \"${title}\" -LoadBalancePercent ${loadbalancepercent}",
      unless  => "if ((Get-DhcpServerv4Failover \"${title}\").LoadBalancePercent -ne ${loadbalancepercent}) { exit 1 }",
    }
  } else {
    $mode_options = "-ReservePercent ${reservepercent} -ServerRole ${serverrole}"

    exec { "set ${title} reservepercent":
      command => "Set-DhcpServerv4Failover \"${title}\" -ReservePercent ${reservepercent}",
      unless  => "if ((Get-DhcpServerv4Failover \"${title}\").ReservePercent -ne ${reservepercent}) { exit 1 }",
    }

    exec { "set ${title} serverrole":
      command => "Set-DhcpServerv4Failover \"${title}\" -ServerRole ${serverrole}",
      unless  => "if ((Get-DhcpServerv4Failover \"${title}\").ServerRole -ne ${serverrole}) { exit 1 }",
    }
  }

  exec { "add ${title}":
    command => "Add-DhcpServerv4Failover -Name \"${title}\" -ScopeId ${subnets} -PartnerServer ${partnerserver} ${common_options} ${mode_options} -Force",
    unless  => "if (Get-DhcpServerv4Failover \"${title}\") { exit 0 } else { exit 1 }",
    require => undef,
  }

  exec { "set ${title} autostatetransition":
    command => "Set-DhcpServerv4Failover \"${title}\" -AutoStateTransition ${autostatetransition}",
    unless  => "if ((Get-DhcpServerv4Failover \"${title}\").AutoStateTransition -ne ${autostatetransition}) { exit 1 }",
  }

  exec { "set ${title} maxclientleadtime":
    command => "Set-DhcpServerv4Failover \"${title}\" -MaxClientLeadTime ${maxclientleadtime}",
    unless  => "if ((Get-DhcpServerv4Failover \"${title}\").MaxClientLeadTime -ne \"${maxclientleadtime}\") { exit 1 }",
  }

  exec { "set ${title} mode":
    command => "Set-DhcpServerv4Failover \"${title}\" -Mode ${mode}",
    unless  => "if ((Get-DhcpServerv4Failover \"${title}\").Mode -ne ${mode}) { exit 1 }",
  }

  exec { "set ${title} stateswitchinterval":
    command => "Set-DhcpServerv4Failover \"${title}\" -StateSwitchInterval ${stateswitchinterval}",
    unless  => "if ((Get-DhcpServerv4Failover \"${title}\").StateSwitchInterval -ne ${stateswitchinterval}) { exit 1 }",
  }

  # Use a basic powershell script on the file system to keep the failover scopes in sync

  file { 'Update-DhcpServerv4FailoverScope.ps1':
    ensure => present,
    path   => 'C:/Windows/Temp/Update-DhcpServerv4FailoverScope.ps1',
    source => 'puppet:///modules/windows_dhcp/Update-DhcpServerv4FailoverScope.ps1',
  }

  exec { "set ${title} subnets":
    command => "C:/Windows/Temp/Update-DhcpServerv4FailoverScope.ps1' -Name \"${title}\" -ScopeId $subnets",
    unless  => "if ((Compare-Object (Get-DhcpServerv4Failover \"${title}\").ScopeId ${subnets}).count -gt 0) { write 1 }",
    require => [Exec["add ${title}"], File['Update-DhcpServerv4FailoverScope.ps1']],
  }
}
