class quickstack::pacemaker::ceilometer (
  $ceilometer_metering_secret,
  $memcached_port          = '11211',
  $db_port                 = '27017',
  $verbose                 = 'false',
) {

  include quickstack::pacemaker::common

  if (str2bool_i(map_params('include_ceilometer'))) {
    $pcmk_ceilometer_group = map_params("ceilometer_group")
    $ceilometer_public_vip  = map_params("ceilometer_public_vip")
    $ceilometer_private_vip = map_params("ceilometer_private_vip")
    $ceilometer_admin_vip   = map_params("ceilometer_admin_vip")
    $backend_ips =  map_params("lb_backend_server_addrs")
    $_memcached_servers = split(inline_template('<%= @backend_ips.map {
      |x| x+":"+@memcached_port }.join(",")%>'),",")
    $_db_servers = split(inline_template('<%= @backend_ips.map {
      |x| x+":"+@db_port }.join(",")%>'),",")
    # TODO: extract this into a helper function
    if ($::pcs_setup_ceilometer ==  undef or
        !str2bool_i("$::pcs_setup_ceilometer")) {
      $_enabled = true
      $_ensure = 'running'
    } else {
      $_enabled = false
      $_ensure = undef
    }

    if (str2bool_i(map_params('include_mysql'))) {
      Exec['galera-online'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_keystone'))) {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_swift'))) {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_glance'))) {
      Exec['all-glance-nodes-are-up'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_nova'))) {
      Exec['all-nova-nodes-are-up'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_cinder'))) {
      Exec['all-cinder-nodes-are-up'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_neutron'))) {
      Exec['all-neutron-nodes-are-up'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_heat'))) {
      Exec['all-heat-nodes-are-up'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_horizon'))) {
      Exec['all-horizon-nodes-are-up'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_nosql'))) {
      Anchor['ha mongo ready'] -> Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    }

    Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip'] -> Exec<| title == 'ceilometer-dbsync' |> -> Exec['pcs-ceilometer-server-set-up']

    class {"::quickstack::load_balancer::ceilometer":
      frontend_pub_host    => $ceilometer_public_vip,
      frontend_priv_host   => $ceilometer_private_vip,
      frontend_admin_host  => $ceilometer_admin_vip,
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "$pcmk_ceilometer_group":
      public_vip  => $ceilometer_public_vip,
      private_vip => $ceilometer_private_vip,
      admin_vip   => $ceilometer_admin_vip,
    }
    ->
    exec {"i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash i_am_vip $ceilometer_private_vip || /tmp/ha-all-in-one-util.bash property_exists ceilometer",
      unless    => "/tmp/ha-all-in-one-util.bash i_am_vip $ceilometer_private_vip || /tmp/ha-all-in-one-util.bash property_exists ceilometer",
    }
    ->
    class { '::quickstack::ceilometer::control':
      amqp_provider              => map_params('amqp_provider'),
      amqp_host                  => map_params('amqp_vip'),
      amqp_port                  => map_params('amqp_port'),
      amqp_username              => map_params('amqp_username'),
      amqp_password              => map_params('amqp_password'),
      auth_host                  => map_params("keystone_admin_vip"),
      bind_address               => map_params("local_bind_addr"),
      ceilometer_metering_secret => "$ceilometer_metering_secret",
      ceilometer_user_password   => map_params('ceilometer_user_password'),
      ceilometer_pub_host        => "$ceilometer_public_vip",
      ceilometer_priv_host       => "$ceilometer_private_vip",
      ceilometer_admin_host      => "$ceilometer_admin_vip",
      db_hosts                   => $_db_servers,
      memcache_servers           => $_memcached_servers,
      qpid_protocol              => map_params(''),
      service_enable             => $_enabled,
      service_ensure             => $_ensure,
    }
    ->
    exec {"pcs-ceilometer-server-set-up":
      command => "/usr/sbin/pcs property set ceilometer=running --force",
    }
    ->
    exec {"pcs-ceilometer-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property ceilometer"
    }
    ->
    exec {"all-ceilometer-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include ceilometer",
    }
    ->
    quickstack::pacemaker::resource::service {'openstack-ceilometer-central':
      clone          => false,
      options        => 'start-delay=10s',
      monitor_params => {'start-delay'     => '10s'},
    }
    ->
    quickstack::pacemaker::resource::service {
      ["openstack-ceilometer-collector",
      "openstack-ceilometer-api",
      "openstack-ceilometer-alarm-evaluator",
      "openstack-ceilometer-alarm-notifier",
      "openstack-ceilometer-notification"]:
      clone => true,
      options => 'start-delay=10s',
      monitor_params => {'start-delay' => '10s'},
    }
    ->
    pcmk_resource { "ceilometer-delay":
      ensure          => 'present',
      resource_type   => "Delay",
      resource_params => 'startdelay=10',
      group           => '',
      clone           => true,
      interval        => '30s',
    }
    ->
    quickstack::pacemaker::constraint::base { "central-collector-constr":
      constraint_type => "order",
      first_resource  => "openstack-ceilometer-central",
      second_resource => "openstack-ceilometer-collector-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "collector-api-constr":
      constraint_type => "order",
      first_resource  => "openstack-ceilometer-collector-clone",
      second_resource => "openstack-ceilometer-api-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "api-delay-constr":
      constraint_type => "order",
      first_resource  => "openstack-ceilometer-api-clone",
      second_resource => "ceilometer-delay-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "delay-evaluator-constr":
      constraint_type => "order",
      first_resource  => "ceilometer-delay-clone",
      second_resource => "openstack-ceilometer-alarm-evaluator-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "evaluator-notifier-constr":
      constraint_type => "order",
      first_resource  => "openstack-ceilometer-alarm-evaluator-clone",
      second_resource => "openstack-ceilometer-alarm-notifier-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "notifier-notification-constr":
      constraint_type => "order",
      first_resource  => "openstack-ceilometer-alarm-notifier-clone",
      second_resource => "openstack-ceilometer-notification-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    Anchor['pacemaker ordering constraints begin']
  }
}
