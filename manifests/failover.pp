# == Define: windows_dhcp::failover
#
# Use windows_dhcp::failover to configure DHCP failover partnerships for IPv4 scopes. This module
# does not yet support IPv6 failover partnerships.
#
# === Parameters
#
# [*partner_server*]
#   Specifies the IPv4 address, or host name, of the partner DHCP server with which the failover
#   relationship is created. This is a required parameter.
#
# [*scope_id*]
#   Specifies the scope identifiers, in IPv4 address format, which are to be added to the failover
#   relationship. This is a required parameter.
#
# [*mode*]
#   Specifies a mode for the failover relationship. The acceptable values for this parameter are
#   'hotstandby' and 'loadbalance'. The default value is 'loadbalance'.
#
# [*loadbalance_percent*]
#   Specifies the percentage of DHCP client requests which should be served by the DHCP server. The
#   remaining requests would be served by the partner server service. The default value is '50'.
#
# [*max_client_lead_time*]
#   Specifies the maximum client lead time for the failover relationship. The default value is
#   '1:00:00'.
#
# [*reserve_percent*]
#   Specifies the percentage of free IPv4 addresses in the IPv4 address pool of the scope which
#   should be reserved on the standby DHCP server when configured as a hot-standby. In the case of
#   a failover, the IPv4 address from this reserved pool on the standby DHCP server service will be
#   leased to new DHCP clients. The default value is '5'.
#
# [*server_role*]
#   Specifies the role of the local DHCP server service in hot-standby mode. Acceptable values for
#   this parameter are 'active' or 'standby'. The default value is 'active' for the local DHCP server,
#   such as the partner DHCP server that is specified will be a standby DHCP server. The default
#   value is 'active'.
#
# [*shared_secret*]
#   Specifies the shared secret to be used for message digest authentication. If not specified,
#   then the message digest authentication is turned off. This is only used when creating the
#   failover partnerships; changing this after a partnership has been created will not update the
#   shared secret. To do change the shared secret you will need to use the MMC.
#
# [*state_switch_interval*]
#   Specifies the time interval for which the DHCP server operates in the COMMUNICATION INTERRUPTED
#   state before transitioning to the PARTNER DOWN state. Set to '0' to disable.  The default value
#   is '1:00:00'.
#
define windows_dhcp::failover (
  $partner_server,
  $scope_id,
  $mode = 'loadbalance',
  $loadbalance_percent = 50,
  $max_client_lead_time = '1:00:00',
  $reserve_percent = 5,
  $server_role = 'active',
  $shared_secret = undef,
  $state_switch_interval = '1:00:00',
) {

  Windows_dhcp::Scope <| |> -> Windows_dhcp::Failover[$title]

  validate_re($mode, '(loadbalance|hotstandby)', '$mode must be either loadbalance or hotstandby')
  validate_re($server_role, '(active|standby)', '$server_role must be either active or standby')

  if is_array($scope_id) {
    $escaped = join(prefix(suffix($scope_id,'\''),'\''),',')
    $subnets = "@(${escaped})"
  } else {
    $subnets = $scope_id
  }

  if $state_switch_interval == "0" or $state_switch_interval == undef {
    $autostatetransition = '$false'
  } else {
    $autostatetransition = '$true'
  }

  $common_options = "-AutoStateTransition ${autostatetransition} -MaxClientLeadTime ${max_client_lead_time} -SharedSecret \"${shared_secret}\" -StateSwitchInterval ${state_switch_interval}"

  Exec {
    provider => 'powershell',
    require  => Exec["add ${title}"]
  }

  $mode_options = $mode ? {
    'hotstandby' => "-ReservePercent ${reserve_percent} -ServerRole ${server_role}",
    default      => "-LoadBalancePercent ${loadbalance_percent}"
  }

  if $mode == 'loadbalance' {
    exec { "set ${title} loadbalance_percent":
      command => "Set-DhcpServerv4Failover \"${title}\" -LoadBalancePercent ${loadbalance_percent}",
      unless  => "if ((Get-DhcpServerv4Failover \"${title}\").LoadBalancePercent -ne ${loadbalance_percent}) { exit 1 }",
    }
  } else {
    exec { "set ${title} reserve_percent":
      command => "Set-DhcpServerv4Failover \"${title}\" -ReservePercent ${reserve_percent}",
      unless  => "if ((Get-DhcpServerv4Failover \"${title}\").ReservePercent -ne ${reserve_percent}) { exit 1 }",
    }

    exec { "set ${title} server_role":
      command => "Set-DhcpServerv4Failover \"${title}\" -ServerRole ${server_role}",
      unless  => "if ((Get-DhcpServerv4Failover \"${title}\").ServerRole -ne ${server_role}) { exit 1 }",
    }
  }

  exec { "add ${title}":
    command => "Add-DhcpServerv4Failover -Name \"${title}\" -ScopeId ${subnets} -PartnerServer ${partner_server} ${common_options} ${mode_options} -Force",
    unless  => "if (Get-DhcpServerv4Failover \"${title}\") { exit 0 } else { exit 1 }",
    require => undef,
  }

  exec { "set ${title} autostatetransition":
    command => "Set-DhcpServerv4Failover \"${title}\" -AutoStateTransition ${autostatetransition}",
    unless  => "if ((Get-DhcpServerv4Failover \"${title}\").AutoStateTransition -ne ${autostatetransition}) { exit 1 }",
  }

  exec { "set ${title} max_client_lead_time":
    command => "Set-DhcpServerv4Failover \"${title}\" -MaxClientLeadTime ${max_client_lead_time}",
    unless  => "if ((Get-DhcpServerv4Failover \"${title}\").MaxClientLeadTime -ne \"${max_client_lead_time}\") { exit 1 }",
  }

  exec { "set ${title} mode":
    command => "Set-DhcpServerv4Failover \"${title}\" -Mode ${mode}",
    unless  => "if ((Get-DhcpServerv4Failover \"${title}\").Mode -ne ${mode}) { exit 1 }",
  }

  exec { "set ${title} state_switch_interval":
    command => "Set-DhcpServerv4Failover \"${title}\" -StateSwitchInterval ${state_switch_interval}",
    unless  => "if ((Get-DhcpServerv4Failover \"${title}\").StateSwitchInterval -ne ${state_switch_interval}) { exit 1 }",
  }

  # Use a basic PowerShell script on the file system to keep the failover scopes in sync
  #
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
