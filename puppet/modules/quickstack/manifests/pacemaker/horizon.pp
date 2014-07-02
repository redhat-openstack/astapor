class quickstack::pacemaker::horizon (
  $horizon_cert            = undef,
  $horizon_key             = undef,
  $horizon_ca              = undef,
  $keystone_default_role   = '_member_',
  $memcached_port          = '11211',
  $secret_key,
  $verbose                 = 'false',
) {

  include quickstack::pacemaker::common

  if (map_params('include_horizon') == 'true') {
    $pcmk_horizon_group = map_params("horizon_group")
    $horizon_public_vip  = map_params("horizon_public_vip")
    $horizon_private_vip = map_params("horizon_private_vip")
    $horizon_admin_vip   = map_params("horizon_admin_vip")
    $memcached_ips =  map_params("lb_backend_server_addrs")
    $memcached_servers = split(
      inline_template('<%= @memcached_ips.map {
        |x| x+":"+@memcached_port }.join(",") %>'),
        ','
    )

    Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip'] -> Service['httpd']
    if (map_params('include_mysql') == 'true') {
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
      Exec['all-galera-nodes-are-up'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
=======
       if str2bool_i("$hamysql_is_running") {
         Exec['mysql-has-users'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
       }
>>>>>>> Updating astapor for ICE HOUSE
=======
      if str2bool_i("$hamysql_is_running") {
        Exec['mysql-has-users'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
      }
>>>>>>> sync with redhat/astapor-master
=======
      Exec['all-galera-nodes-are-up'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
>>>>>>> syncing with redhat repo
    }
    if (map_params('include_keystone') == 'true') {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
    }
    if (map_params('include_swift') == 'true') {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
    }
    if (map_params('include_glance') == 'true') {
      Exec['all-glance-nodes-are-up'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
    }
    if (map_params('include_cinder') == 'true') {
      Exec['all-cinder-nodes-are-up'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
    }
    if (map_params('include_nova') == 'true') {
      Exec['all-nova-nodes-are-up'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
    }
    if (map_params('include_neutron') == 'true') {
      Exec['all-neutron-nodes-are-up'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
    }
    if (map_params('include_heat') == 'true') {
      Exec['all-heat-nodes-are-up'] -> Exec['i-am-horizon-vip-OR-horizon-is-up-on-vip']
    }

    class {"::quickstack::load_balancer::horizon":
      frontend_pub_host    => $horizon_public_vip,
      frontend_priv_host   => $horizon_private_vip,
      frontend_admin_host  => $horizon_admin_vip,
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "$pcmk_horizon_group":
      public_vip  => $horizon_public_vip,
      private_vip => $horizon_private_vip,
      admin_vip   => $horizon_admin_vip,
    }
    ->
    exec {"i-am-horizon-vip-OR-horizon-is-up-on-vip":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash i_am_vip $horizon_private_vip || /tmp/ha-all-in-one-util.bash property_exists horizon",
      unless    => "/tmp/ha-all-in-one-util.bash i_am_vip $horizon_private_vip || /tmp/ha-all-in-one-util.bash property_exists horizon",
    }
    ->
    class { '::quickstack::horizon':
      bind_address          => map_params("local_bind_addr"),
      fqdn                  => ["$horizon_public_vip",
                                "$horizon_private_vip",
                                "$horizon_admin_vip",
                                "$::fqdn",
                                "$::hostname",
                                "localhost"],
      horizon_cert          => $horizon_cert,
      horizon_key           => $horizon_key,
      horizon_ca            => $horizon_ca,
      keystone_default_role => $keystone_default_role,
      keystone_host         => map_params("keystone_admin_vip"),
      memcached_servers     => $memcached_servers,
      secret_key            => $secret_key,
    }
    ->
    exec {"pcs-horizon-server-set-up":
      command => "/usr/sbin/pcs property set horizon=running --force",
    }
    ->
    exec {"pcs-horizon-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property horizon"
    }
    ->
    exec {"all-horizon-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include horizon",
    }
    ->
<<<<<<< HEAD
<<<<<<< HEAD
    quickstack::pacemaker::resource::service {"$::horizon::params::http_service":
=======
    quickstack::pacemaker::resource::lsb {"$::horizon::params::http_service":
=======
    quickstack::pacemaker::resource::service {"$::horizon::params::http_service":
<<<<<<< HEAD
>>>>>>> sync with redhat/astapor-master
      group => "$::horizon::params::http_service",
>>>>>>> Updating astapor for ICE HOUSE
=======
>>>>>>> syncing with redhat repo
      clone => true,
      options => 'start-delay=10s',
    }
  }
}
