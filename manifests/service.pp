# == Class windows_dhcp::service
#
# This class is meant to be called from windows_dhcp
# It ensure the service is running
#
class windows_dhcp::service {

  service { 'dhcpserver':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
