# == Class windows_dhcp::install
#
class windows_dhcp::install {

  windowsfeature { 'dhcp':
    installmanagementtools =>  true
  }
}
