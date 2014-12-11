# == Class windows_dhcp::service
#
# This class is meant to be called from windows_dhcp, it ensures the service is running.
#
class windows_dhcp::service {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  service { 'dhcpserver':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
