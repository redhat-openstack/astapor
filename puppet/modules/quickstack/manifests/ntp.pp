class quickstack::ntp (
  $preferred_servers = [],
  $servers           = ['0.centos.pool.ntp.org',
                        '1.centos.pool.ntp.org',
                        '2.centos.pool.ntp.org',],
) {
  class {'::ntp':
    preferred_servers => $preferred_servers,
    servers           => $servers,
  }
}
