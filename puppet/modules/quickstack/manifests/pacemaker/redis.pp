class quickstack::pacemaker::redis(
  $bind_host             = '127.0.0.1',
  $port                  = '6379',
  $slaveof               = undef,
) {

  $redis_group = map_params("redis_group")

  class {'::quickstack::firewall::redis':
    ports => [$port],
  }

  if ($::pcs_setup_redis ==  undef or
      !str2bool_i("$::pcs_setup_redis")) {
    # different pattern than the usual-- the service is started in the first
    # puppet run by pacemaker which happens after puppet-redis config.
    $_ensure = 'stopped'
  } else {
    $_enabled = false
  }

  class {'::quickstack::db::redis':
    bind_host      => $bind_host,
    port           => $port,
    slaveof        => $slaveof,
    service_enable => false,
    service_ensure => $_ensure,
  }

  $_redis_vip = map_params('redis_vip')
  validate_string($_redis_vip)

  anchor {'redis-begin': }
  ->
  Class[::redis]
  ->
  exec {"pcs-redis-server-set-up-on-this-node":
    command => "/tmp/ha-all-in-one-util.bash update_my_node_property redis"
  }
  ->
  exec {"all-redis-nodes-are-configured":
    timeout   => 3600,
    tries     => 360,
    try_sleep => 10,
    command   => "/tmp/ha-all-in-one-util.bash all_members_include redis",
  }
  ->
  quickstack::pacemaker::resource::generic {'redis':
    resource_name => '',
    resource_type => 'redis',
    resource_params => "wait_last_known_master=true --master meta notify=true ordered=true interleave=true",
  }
  ->
  quickstack::pacemaker::vips { $redis_group:
    public_vip   => $_redis_vip,
    private_vip  => $_redis_vip,
    admin_vip    => $_redis_vip,
  }
  ->
  quickstack::pacemaker::constraint::base { 'redis-master-then-vip-redis':
    constraint_type => "order",
    first_resource  => 'redis-master',
    second_resource => "ip-redis-pub-${_redis_vip}",
    first_action    => 'promote',
    second_action   => "start",
  }
  ->
  # if the constraint has been created, redis should be up
  exec {'redis-master-is-up':
    timeout   => 3600,
    tries     => 360,
    try_sleep => 10,
    command => "bash -c 'pcs constraint show | grep -qs \"ip-redis-pub-${_redis_vip} with redis-master\"'",
    path => ['/usr/sbin', '/usr/bin'],
  }

  class {"::quickstack::load_balancer::redis":
    frontend_pub_host    => $_redis_vip,
    frontend_priv_host   => $_redis_vip,
    frontend_admin_host  => $_redis_vip,
    backend_server_names => map_params("lb_backend_server_names"),
    backend_server_addrs => map_params("lb_backend_server_addrs"),
  }

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    # using an exec here because of the "with master" clause which
    # current colocation classes do not support.
    Quickstack::Pacemaker::Constraint::Base['redis-master-then-vip-redis']
    ->
    exec{ 'redis-master-and-vip-colo':
      command => "pcs constraint colocation add ip-redis-pub-${_redis_vip} with master redis-master",
      unless => "bash -c 'pcs constraint show | grep -qs \"ip-redis-pub-${_redis_vip} with redis-master\"'",
      path => ['/usr/sbin', '/usr/bin'],
    }
    ->
    Exec['redis-master-is-up']
  }

}
