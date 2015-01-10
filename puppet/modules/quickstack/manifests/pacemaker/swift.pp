class quickstack::pacemaker::swift (
  $swift_shared_secret    = '',
  $swift_storage_ips      = [],
  $swift_storage_device   = '',
  $swift_internal_vip     = '',
  $memcached_port         = '11211',  # maybe move to params.pp since also in nova.pp
) {
  include quickstack::pacemaker::common

  if (str2bool_i(map_params('include_swift'))) {
    $swift_group = map_params("swift_group")
    $swift_public_vip = map_params("swift_public_vip")
    $memcached_ips =  map_params("lb_backend_server_addrs")
    $memcached_servers_str = inline_template('<%= @memcached_ips.map {
        |x| x+":"+@memcached_port }.join(",") %>')

    Exec['i-am-swift-vip-OR-swift-is-up-on-vip'] -> Service['swift-proxy']
    if (str2bool_i(map_params('include_keystone'))) {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-swift-vip-OR-swift-is-up-on-vip']
    }

    class {"::quickstack::load_balancer::swift":
      frontend_pub_host    => map_params("swift_public_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "$swift_group":
      public_vip  => map_params("swift_public_vip"),
      private_vip => $swift_internal_vip,
      admin_vip   => $swift_internal_vip,
    }
    ->
    exec {"i-am-swift-vip-OR-swift-is-up-on-vip":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash i_am_vip $swift_internal_vip || /tmp/ha-all-in-one-util.bash property_exists swift",
      unless   => "/tmp/ha-all-in-one-util.bash i_am_vip $swift_internal_vip || /tmp/ha-all-in-one-util.bash property_exists swift",
    }
    ->
    quickstack::pacemaker::rsync::get { '/etc/swift':
      source           => "rsync://$swift_internal_vip/swift_server/",
      override_options => "aI",
      purge            => true,
      exclude          => '*.conf',
      unless           => "/tmp/ha-all-in-one-util.bash i_am_vip $swift_internal_vip",
    }
    ->
    file_line { 'set_memcache_servers_for_swift_proxy':
      path    => '/etc/swift/proxy-server.conf',
      match   => '^memcache_servers.*=.*$',
      line    => "memcache_servers = $memcached_servers_str" ,
      require => Package['openstack-swift-proxy'],
      notify  => Service['swift-proxy'],
    }
    ->
    file_line { 'set_memcache_servers_for_swift_object_expirer':
      path    => '/etc/swift/object-expirer.conf',
      match   => '^memcache_servers.*$',
      line    => "memcache_servers = $memcached_servers_str",
      require => Package['openstack-swift-proxy'],
      notify  => Service['swift-proxy'],
    }
    ->
    class { 'quickstack::swift::proxy':
      swift_proxy_host     => map_params("local_bind_addr"),
      keystone_host        => map_params("keystone_public_vip"),
      swift_admin_password => map_params("swift_user_password"),
      swift_shared_secret  => $swift_shared_secret,
      swift_ringserver_ip  => $swift_internal_vip,
      swift_is_ringserver  => true,
      swift_storage_ips    => $swift_storage_ips,
      swift_storage_device => $swift_storage_device,
    }
    ->
    # no way to do this with puppet-swift, so exec for now
    exec {"set-object-expirer-concurrency":
      command => "/usr/bin/openstack-config --set /etc/swift/object-expirer.conf object-expirer concurrency 100",
    } ->
    exec {"pcs-swift-server-set-up":
      command => "/usr/sbin/pcs property set swift=running --force",
    } ->
    exec {"pcs-swift-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property swift"
    } ->
    exec {"all-swift-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include swift",
    } ->
    quickstack::pacemaker::resource::service {'openstack-swift-proxy':
      clone => true,
    } ->
    quickstack::pacemaker::resource::service {'openstack-swift-object-expirer':
      group => "$swift_group",
      clone => false,
    }
    ->
    quickstack::pacemaker::constraint::base { 'swift-object-expirer-constr' :
      constraint_type => "order",
      first_resource  => "openstack-swift-proxy-clone",
      second_resource => "openstack-swift-object-expirer",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    Anchor['pacemaker ordering constraints begin']
  }
}
