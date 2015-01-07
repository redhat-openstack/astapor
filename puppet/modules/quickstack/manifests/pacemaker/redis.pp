class quickstack::pacemaker::redis(
  $bind_host             = '127.0.0.1',
  $port                  = '6379',
  $slaveof               = undef,
) {

  class {'::quickstack::firewall::redis':
    ports => [$port],
  }

  class {'::quickstack::db::redis':
    bind_host => $bind_host,
    port      => $port,
    slaveof   => $slaveof,
  }
}
