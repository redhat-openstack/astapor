# Class for Nagios server
class quickstack::monitor::nagios::server (
  $admin_password = $quickstack::params::admin_password,
  $controller_ip  = $quickstack::params::controller_priv_floating_ip,
  $neutron        = $quickstack::params::neutron,
  $swift          = $quickstack::params::swift,
  $nagios_group   = 'nagios',
  $nagios_user    = 'nagios',
  $nagios_admin   = 'nagiosadmin',
  ) inherits quickstack::params {

  Exec { timeout => 300 }

  File {
    owner => $nagios_user,
    group => $nagios_group,
  }

  package {['nagios', 'nagios-plugins-nrpe', 'nagios-plugins-ping']:
    ensure => present,
  }

  class {'quickstack::monitor::nagios::server::config':
    admin_password => $admin_password,
    controller_ip  => $controller_ip,
    neutron        => $neutron,
    nagios_admin   => $nagios_admin,
    nagios_user    => $nagios_user,
    nagios_group   => $nagios_group,
    swift          => $swift,
    require        => Package['nagios'],
    notify         => Service['httpd'],
  }

  class {'apache':}
  class {'apache::mod::php':}
  class {'apache::mod::wsgi':}
  # The apache module purges files it doesn't know about
  # avoid this by referencing them here
  file {'/etc/httpd/conf.d/openstack-dashboard.conf':}
  file {'/etc/httpd/conf.d/rootredirect.conf':}
  file {'/etc/httpd/conf.d/nagios.conf':}

  service {['nagios']:
    ensure    => running,
    enable    => true,
    hasstatus => true,
  }

  firewall {'001 nagios incoming':
    proto    => 'tcp',
    dport    => ['80'],
    action   => 'accept',
  }
}
