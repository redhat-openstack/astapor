class quickstack::pacemaker::redis(
  $bind_host             = '127.0.0.1',
  $port                  = '6379',
  $master_host           = '127.0.0.1',
  $monitoring_port       = '26379',
  $monitoring_group      = 'sentinel-group',
  $slaveof               = undef,
) {

  class {'::quickstack::firewall::redis':
    ports => [$port, $monitoring_port],
  }

  class {'::quickstack::db::redis':
    bind_host => $bind_host,
    port      => $port,
    master_host => $master_host,
    monitoring_port => $monitoring_port,
    monitoring_group => $monitoring_group,
    slaveof   => $slaveof,
  }
}
