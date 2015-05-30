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


class quickstack::db::redis(
  $bind_host             = '127.0.0.1',
  $port                  = '6379',
  $slaveof               = undef,
  $service_enable        = false,
  $service_ensure        = undef,
) {

  class { '::redis':
    bind           => $bind_host,
    port           => $port,
    appendonly     => true,
    daemonize      => false,
    slaveof        => $slaveof,
    service_enable => $service_enable,
    service_ensure => $service_ensure,
  }

}
