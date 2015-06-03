class quickstack::pacemaker::heat(
  $db_name             = 'heat',
  $db_user             = 'heat',

  $db_ssl              = false,
  $db_ssl_ca           = undef,

  $qpid_heartbeat      = '60',

  $use_syslog          = false,
  $log_facility        = 'LOG_USER',

  $debug               = false,
  $verbose             = false,
) {

  include ::quickstack::pacemaker::common

  if (str2bool_i(map_params('include_heat'))) {

    include ::quickstack::pacemaker::amqp

    $heat_db_password        = map_params("heat_db_password")
    $heat_cfn_enabled        = map_params("heat_cfn_enabled")
    $heat_cloudwatch_enabled = map_params("heat_cloudwatch_enabled")
    $heat_group              = map_params("heat_group")
    $heat_cfn_group          = map_params("heat_cfn_group")
    $heat_private_vip        = map_params("heat_private_vip")

    # TODO: extract this into a helper function
    if ($::pcs_setup_heat ==  undef or
        !str2bool_i("$::pcs_setup_heat")) {
      $_enabled = true
    } else {
      $_enabled = false
    }

    class {"::quickstack::load_balancer::heat":
      frontend_heat_pub_host              => map_params("heat_public_vip"),
      frontend_heat_priv_host             => map_params("heat_private_vip"),
      frontend_heat_admin_host            => map_params("heat_admin_vip"),
      frontend_heat_cfn_pub_host          => map_params("heat_cfn_public_vip"),
      frontend_heat_cfn_priv_host         => map_params("heat_cfn_private_vip"),
      frontend_heat_cfn_admin_host        => map_params("heat_cfn_admin_vip"),
      backend_server_names                => map_params("lb_backend_server_names"),
      backend_server_addrs                => map_params("lb_backend_server_addrs"),
      heat_cfn_enabled                    => $heat_cfn_enabled,
      heat_cloudwatch_enabled             => $heat_cloudwatch_enabled,
    }

    Exec['i-am-heat-vip-OR-heat-is-up-on-vip'] -> Exec<| title == 'heat-dbsync' |>
    -> Exec['pcs-heat-server-set-up']
    Exec['i-am-heat-vip-OR-heat-is-up-on-vip'] -> Service<| title =='heat-engine' |>

    if (str2bool_i(map_params('include_mysql'))) {
      Anchor['galera-online'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_keystone'))) {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_swift'))) {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_glance'))) {
      Exec['all-glance-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_nova'))) {
      Exec['all-nova-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_cinder'))) {
      Exec['all-cinder-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_neutron'))) {
      Exec['all-neutron-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }

    Class['::quickstack::pacemaker::amqp']
    ->
    quickstack::pacemaker::vips { "$heat_group":
      public_vip  => map_params("heat_public_vip"),
      private_vip => map_params("heat_private_vip"),
      admin_vip   => map_params("heat_admin_vip"),
    }
    ->
    exec {"i-am-heat-vip-OR-heat-is-up-on-vip":
      timeout => 3600,
      tries => 360,
      try_sleep => 10,
      command => "/tmp/ha-all-in-one-util.bash i_am_vip $heat_private_vip || /tmp/ha-all-in-one-util.bash property_exists heat",
      unless => "/tmp/ha-all-in-one-util.bash i_am_vip $heat_private_vip || /tmp/ha-all-in-one-util.bash property_exists heat",
    }
    ->
    class {'::quickstack::heat':
      heat_user_password      => map_params("heat_user_password"),
      heat_cfn_user_password  => map_params("heat_cfn_user_password"),
      auth_encryption_key     => map_params("heat_auth_encryption_key"),
      bind_host               => map_params("local_bind_addr"),
      db_host                 => map_params("db_vip"),
      db_name                 => $db_name,
      db_user                 => $db_user,
      db_password             => $heat_db_password,
      max_retries             => '-1',
      db_ssl                  => $db_ssl,
      db_ssl_ca               => $db_ssl_ca,
      keystone_host           => map_params("keystone_admin_vip"),
      qpid_heartbeat          => $qpid_heartbeat,
      amqp_host               => map_params("amqp_vip"),
      amqp_port               => map_params("amqp_port"),
      amqp_username           => map_params("amqp_username"),
      amqp_password           => map_params("amqp_password"),
      amqp_provider           => map_params("amqp_provider"),
      rabbit_hosts            => map_params("rabbitmq_hosts"),
      cfn_host                => map_params("heat_cfn_admin_vip"),
      cloudwatch_host         => map_params("heat_admin_vip"),
      use_syslog              => $use_syslog,
      log_facility            => $log_facility,
      enabled                 => $_enabled,
      manage_service          => $_enabled,
      debug                   => $debug,
      verbose                 => $verbose,
      heat_cfn_enabled        => $_enabled,
      heat_cloudwatch_enabled => $_enabled,
      heat_engine_enabled     => false,
      engine_cfg_delegated    => has_interface_with("ipaddress", map_params("cluster_control_ip")),
    }
    ->
    exec {"pcs-heat-server-set-up":
      command => "/usr/sbin/pcs property set heat=running --force",
    }
    ->
    exec {"pcs-heat-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property heat"
    }
    ->
    exec {"all-heat-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include heat",
    }
    ->
    quickstack::pacemaker::resource::generic {'heat-api':
      clone_opts      => "interleave=true",
      resource_name   => "openstack-heat-api",
    }
    ->
    quickstack::pacemaker::resource::generic {'heat-engine':
      resource_name   => "openstack-heat-engine",
    }

    if str2bool_i($heat_cfn_enabled) {
      Class['::quickstack::pacemaker::amqp']
      ->
      quickstack::pacemaker::vips {"$heat_cfn_group":
        public_vip  => map_params("heat_cfn_public_vip"),
        private_vip => map_params("heat_cfn_private_vip"),
        admin_vip   => map_params("heat_cfn_admin_vip"),
      }
      ->
      Exec["i-am-heat-vip-OR-heat-is-up-on-vip"] ->
      Service[openstack-heat-api-cfn] ->
      Quickstack::Pacemaker::Resource::Generic['heat-engine']
      ->
      quickstack::pacemaker::resource::generic {"heat-api-cfn":
        clone_opts      => "interleave=true",
        resource_name   => "openstack-heat-api-cfn",
      }
      ->
      quickstack::pacemaker::constraint::base { 'heat-api-cfn-constr' :
        constraint_type => "order",
        first_resource  => "heat-api-clone",
        second_resource => "heat-api-cfn-clone",
        first_action    => "start",
        second_action   => "start",
      }
      ->
      quickstack::pacemaker::constraint::colocation { 'heat-api-cfn-colo' :
        source => "heat-api-cfn-clone",
        target => "heat-api-clone",
        score => "INFINITY",
      }
    }

    if str2bool_i($heat_cloudwatch_enabled) {
      Quickstack::Pacemaker::Resource::Generic['heat-engine']
      ->
      quickstack::pacemaker::resource::generic {"heat-api-cloudwatch":
        clone_opts      => "interleave=true",
        resource_name   => "openstack-heat-api-cloudwatch",
      }
      if str2bool_i($heat_cfn_enabled) {
        Quickstack::Pacemaker::Resource::Generic['heat-api-cfn'] ->
        Quickstack::Pacemaker::Resource::Generic['heat-api-cloudwatch'] ->
        quickstack::pacemaker::constraint::base { 'heat-cfn-cloudwatch-constr' :
          constraint_type => "order",
          first_resource  => "heat-api-cfn-clone",
          second_resource => "heat-api-cloudwatch-clone",
          first_action    => "start",
          second_action   => "start",
        }
        ->
        quickstack::pacemaker::constraint::colocation { 'heat-cfn-cloudwatch-colo' :
          source => "heat-api-cloudwatch-clone",
          target => "heat-api-cfn-clone",
          score => "INFINITY",
        }
        ->
        quickstack::pacemaker::constraint::base { 'heat-cloudwatch-engine-constr' :
          constraint_type => "order",
          first_resource  => "heat-api-cloudwatch-clone",
          second_resource => "heat-engine",
          first_action    => "start",
          second_action   => "start",
        }
        ->
        quickstack::pacemaker::constraint::colocation { 'heat-cloudwatch-engine-colo' :
          source => "heat-engine",
          target => "heat-api-cloudwatch-clone",
          score => "INFINITY",
        }
      }
    }
  }
}
