class quickstack::tuned::virtual_host {
  include quickstack::tuned::common

  exec {'tuned-virtual-host':
    unless  => '/usr/sbin/tuned-adm active | /bin/grep virtual-host',
    command => '/usr/sbin/tuned-adm profile virtual-host',
    require => Service['tuned'],
    subscribe => Service['tuned'],
  }
}
