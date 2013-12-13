# Nagios server configuration
class quickstack::monitor::nagios::server::config(
  $admin_password,
  $controller_ip,
  $nagios_admin,
  $nagios_group,
  $nagios_user,
  $neutron,
  $swift,
) {

  class { 'quickstack::monitor::nagios::server::base':
    admin_password => $admin_password,
    nagios_admin   => $nagios_admin,
    nagios_user    => $nagios_user,
    nagios_group   => $nagios_group,
    require        => Package['nagios'],
  }

  class { 'quickstack::monitor::nagios::server::nrpe':
    require => Class['quickstack::monitor::nagios::server::base'],
    before  => Service['nagios'],
  }

  class { 'quickstack::monitor::nagios::server::openstack':
    admin_password => $admin_password,
    controller_ip  => $controller_ip,
    nagios_user    => $nagios_user,
    nagios_group   => $nagios_group,
    neutron        => $neutron,
    swift          => $swift,
    require        => Class['quickstack::monitor::nagios::server::base'],
    before         => Service['nagios'],
  }
}
