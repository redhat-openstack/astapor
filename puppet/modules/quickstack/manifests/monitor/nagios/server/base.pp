# Nagios server configuration
class quickstack::monitor::nagios::server::base(
  $admin_password,
  $nagios_admin,
  $nagios_group,
  $nagios_user,
) {

  File {
    owner => $nagios_user,
    group => $nagios_group,
  }

  file { ['/etc/nagios/conf.d/commands.cfg', '/etc/nagios/conf.d/hosts.cfg', '/etc/nagios/conf.d/hostgroups.cfg', '/etc/nagios/conf.d/services.cfg']:
    ensure => 'present',
    mode   => 644,
  }

  exec { 'nagiospasswd':
    command => "/usr/bin/htpasswd -b /etc/nagios/passwd $nagios_admin $admin_password",
  }

  # Remove the entry for localhost, it contains services we're not
  # monitoring
  file { ['/etc/nagios/objects/localhost.cfg']:
    ensure  => 'present',
    content => '',
  }
}
