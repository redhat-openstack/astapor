class quickstack::pacemaker::redis(
  $bind_host             = '127.0.0.1',
  $port                  = '6379',
  $slaveof               = undef,
) {

  $redis_group = map_params("redis_group")

  class {'::quickstack::firewall::redis':
    ports => [$port],
  }

  class {'::quickstack::db::redis':
    bind_host => $bind_host,
    port      => $port,
    slaveof   => $slaveof,
  }

  quickstack::pacemaker::resource::generic {'redis':
    resource_name => "redis",
    resource_params => "wait_last_known_master=true --master meta notify=true ordered=true interleave=true",
  } ->

  quickstack::pacemaker::vips { $redis_group:
      public_vip   => map_params('redis_vip'),
      private_vip  => map_params('redis_vip'),
      admin_vip    => map_params('redis_vip'),
    } ->

  exec {"pcs-constraint-order":
      command => "/usr/sbin/pcs constraint order promote redis-master then start vip-redis",
  } ->

  exec {"pcs-constraint-colocation":
      command => "/usr/sbin/pcs colocation add vip-redis with master redis-master",
  }

}
