# == Class: quickstack::db::redis
#
# Install redis
#
# === Parameters:
#
# [*bind_host*]
#   (optional) Configure which IP address to listen on.
#   Defaults to '127.0.0.1'
#
# [*port*]
#   (optional) Configure which port to listen on.
#   Defaults to '6379'
#
# [*monitoring_port*]
#   (optional) Configure which port for sentinel to listen on.
#   Defaults to '26379'
#
# [*monitoring_group*]
#   (optional) Configure which group name for sentinel to use.
#   Defaults to '26379'



class quickstack::db::redis(
  $bind_host             = '127.0.0.1',
  $port                  = '6379',
  $master_host           = '127.0.0.1',
  $monitoring_port       = '26379',
  $monitoring_group      = 'sentinel-group',
  $slaveof               = undef,
) {

  class { '::redis':
    bind       => $bind_host,
    port       => $port,
    appendonly => true,
    daemonize  => false,
    slaveof    => $slaveof,
  }

  class { '::redis::sentinel':
    master_name   => $monitoring_group,
    redis_host    => $master_host,
    redis_port    => $port,
    sentinel_port => $monitoring_port,
  }
}
