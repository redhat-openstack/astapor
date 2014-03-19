class quickstack::tuned::common {

  package {'tuned':
    ensure => present,
  }

  service {'tuned':
    ensure  => running,
    require => Package['tuned'],
  }

  if $::operatingsystem == 'Fedora' and $::operatingsystemrelease == 19 {
    # older tuned service is sometimes stuck on Fedora 19
    exec {'tuned-update':
      path      => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
      command   => 'yum update -y tuned',
      logoutput => 'on_failure',
    }

    exec {'tuned-restart':
      path      => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
      command   => 'systemctl restart tuned.service',
      logoutput => 'on_failure',
    }

    Service['tuned'] -> Exec['tuned-update'] -> Exec['tuned-restart']
  }
}
