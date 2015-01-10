class quickstack::pacemaker::memcached {

  include ::memcached
  include quickstack::pacemaker::common
  class {'::quickstack::firewall::memcached':}

  Exec['wait-for-settle'] -> Exec['pcs-memcached-server-set-up-on-this-node']

  Service['memcached'] ->
  exec {"pcs-memcached-server-set-up-on-this-node":
    command => "/tmp/ha-all-in-one-util.bash update_my_node_property memcached",
  } ->
  exec {"all-memcached-nodes-are-up":
    timeout   => 3600,
    tries     => 360,
    try_sleep => 10,
    command   => "/tmp/ha-all-in-one-util.bash all_members_include memcached",
  } ->
  quickstack::pacemaker::resource::service { 'memcached':
    clone   => true,
    options => 'start-delay=10s',
  } ->
  Anchor['pacemaker ordering constraints begin']
}
