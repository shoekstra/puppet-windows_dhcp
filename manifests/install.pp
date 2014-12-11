# == Class windows_dhcp::install
#
# This class is meant to be called from windows_dhcp, it guides the installation process.
#
class windows_dhcp::install {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  windowsfeature { 'dhcp':
    installmanagementtools =>  true
  }
}
