class quickstack::pacemaker::ceilometer (
  $ceilometer_metering_secret,
  $memcached_port                = '11211',
  $db_port                       = '27017',
  $verbose                       = 'false',
  $coordination_backend          = 'redis',
  $coordination_backend_port     = '6379',
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

    if $coordination_backend == 'redis' {
      $_redis_vip = map_params('redis_vip')
      $_initial_master = $backend_ips[0]
      $_coordination_url = "redis://${_redis_vip}:${coordination_backend_port}"
      $_ceilo_central_clone = "interleave=true"

      if has_interface_with("ipaddress", $_initial_master) {
        $_slaveof = undef
      } else {
        $_slaveof = "${_initial_master} ${coordination_backend_port}"
      }

      class { '::quickstack::pacemaker::redis':
        bind_host => map_params("local_bind_addr"),
        port      => $coordination_backend_port,
        slaveof  => $_slaveof,
      }
      # redis before ceilo (but after other openstack services)
      Anchor['ceilo-before-vip'] ->
      Anchor['redis-begin']
      Exec['redis-master-is-up'] ->
      Exec['i-am-ceilometer-vip-OR-ceilometer-is-up-on-vip']
    } else {
      $_coordination_url = undef
      $_ceilo_central_clone = undef
    }

    if (str2bool_i(map_params('include_mysql'))) {
      Anchor['galera-online'] -> Anchor['ceilo-before-vip']
    }
    if (str2bool_i(map_params('include_keystone'))) {
      Exec['all-keystone-nodes-are-up'] -> Anchor['ceilo-before-vip']
    }
    if (str2bool_i(map_params('include_swift'))) {
      Exec['all-swift-nodes-are-up'] -> Anchor['ceilo-before-vip']
    }
    if (str2bool_i(map_params('include_glance'))) {
      Exec['all-glance-nodes-are-up'] -> Anchor['ceilo-before-vip']
    }
    if (str2bool_i(map_params('include_nova'))) {
      Exec['all-nova-nodes-are-up'] -> Anchor['ceilo-before-vip']
    }
    if (str2bool_i(map_params('include_cinder'))) {
      Exec['all-cinder-nodes-are-up'] -> Anchor['ceilo-before-vip']
    }
    if (str2bool_i(map_params('include_neutron'))) {
      Exec['all-neutron-nodes-are-up'] -> Anchor['ceilo-before-vip']
    }
    if (str2bool_i(map_params('include_heat'))) {
      Exec['all-heat-nodes-are-up'] -> Anchor['ceilo-before-vip']
    }
    if (str2bool_i(map_params('include_horizon'))) {
      Exec['all-horizon-nodes-are-up'] -> Anchor['ceilo-before-vip']
    }
    if (str2bool_i(map_params('include_nosql'))) {
      Anchor['ha mongo ready'] -> Anchor['ceilo-before-vip']
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
    anchor {'ceilo-before-vip': }
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
      rabbit_hosts               => map_params("rabbitmq_hosts"),
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
      verbose                    => $verbose,
      coordination_url           => $_coordination_url,
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
    quickstack::pacemaker::resource::generic { 'ceilometer-central':
      resource_name   => "openstack-ceilometer-central",
      clone_opts      => $_ceilo_central_clone,
    }
    ->
    quickstack::pacemaker::resource::generic {
      [ 'ceilometer-collector',
        'ceilometer-api',
        'ceilometer-alarm-evaluator',
        'ceilometer-alarm-notifier',
        'ceilometer-notification' ]:
      resource_name_prefix => 'openstack-',
      clone_opts      => "interleave=true",
    }
    ->
    quickstack::pacemaker::resource::generic { "ceilometer-delay":
      resource_name   => "",
      resource_type   => "Delay",
      resource_params => "startdelay=10",
      clone_opts      => 'interleave=true',
    }
    ->
    quickstack::pacemaker::constraint::base { "central-collector-constr":
      constraint_type => "order",
      first_resource  => "ceilometer-central-clone",
      second_resource => "ceilometer-collector-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "collector-api-constr":
      constraint_type => "order",
      first_resource  => "ceilometer-collector-clone",
      second_resource => "ceilometer-api-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "api-delay-constr":
      constraint_type => "order",
      first_resource  => "ceilometer-api-clone",
      second_resource => "ceilometer-delay-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "delay-evaluator-constr":
      constraint_type => "order",
      first_resource  => "ceilometer-delay-clone",
      second_resource => "ceilometer-alarm-evaluator-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "evaluator-notifier-constr":
      constraint_type => "order",
      first_resource  => "ceilometer-alarm-evaluator-clone",
      second_resource => "ceilometer-alarm-notifier-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { "notifier-notification-constr":
      constraint_type => "order",
      first_resource  => "ceilometer-alarm-notifier-clone",
      second_resource => "ceilometer-notification-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    Anchor['pacemaker ordering constraints begin']
  }
}
