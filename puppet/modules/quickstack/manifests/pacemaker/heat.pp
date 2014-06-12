class quickstack::pacemaker::heat(
  $db_name             = 'heat',
  $db_user             = 'heat',

  $db_ssl              = false,
  $db_ssl_ca           = undef,

  $qpid_heartbeat      = '60',

  $use_syslog          = false,
  $log_facility        = 'LOG_USER',

  $enabled             = true,
  $debug               = false,
  $verbose             = false,
) {

  include ::quickstack::pacemaker::common

  if (map_params('include_heat') == 'true') {

    include ::quickstack::pacemaker::amqp

    $heat_db_password        = map_params("heat_db_password")
    $heat_cfn_enabled        = map_params("heat_cfn_enabled")
    $heat_cloudwatch_enabled = map_params("heat_cloudwatch_enabled")
    $heat_group              = map_params("heat_group")
    $heat_cfn_group          = map_params("heat_cfn_group")
    $heat_private_vip        = map_params("heat_private_vip")

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
    if (map_params('include_mysql') == 'true') {
      Exec['all-galera-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (map_params('include_keystone') == 'true') {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (map_params('include_swift') == 'true') {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (map_params('include_glance') == 'true') {
      Exec['all-glance-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (map_params('include_nova') == 'true') {
      Exec['all-nova-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (map_params('include_cinder') == 'true') {
      Exec['all-cinder-nodes-are-up'] -> Exec['i-am-heat-vip-OR-heat-is-up-on-vip']
    }
    if (map_params('include_neutron') == 'true') {
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
      db_ssl                  => $db_ssl,
      db_ssl_ca               => $db_ssl_ca,
      keystone_host           => map_params("keystone_admin_vip"),
      qpid_heartbeat          => $qpid_heartbeat,
      amqp_host               => map_params("amqp_vip"),
      amqp_port               => map_params("amqp_port"),
      amqp_username           => map_params("amqp_username"),
      amqp_password           => map_params("amqp_password"),
      amqp_provider           => map_params("amqp_provider"),
      cfn_host                => map_params("heat_cfn_admin_vip"),
      cloudwatch_host         => map_params("heat_admin_vip"),
      use_syslog              => $use_syslog,
      log_facility            => $log_facility,
      enabled                 => $enabled,
      debug                   => $debug,
      verbose                 => $verbose,
      heat_cfn_enabled        => $heat_cfn_enabled,
      heat_cloudwatch_enabled => $heat_cloudwatch_enabled,
      # don't start heat-engine on all hosts, let pacemaker start it on one
      heat_engine_enabled     => false,
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
<<<<<<< HEAD
    quickstack::pacemaker::resource::service {'openstack-heat-api':
=======
    quickstack::pacemaker::resource::lsb {'openstack-heat-api':
      group => "$heat_group",
>>>>>>> Updating astapor for ICE HOUSE
      clone => true,
      options => 'start-delay=10s',
    }
    ->
    quickstack::pacemaker::resource::lsb {'openstack-heat-engine':
      group => "$heat_group",
      clone => false,
      options => 'start-delay=10s',
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
      Exec["i-am-heat-vip-OR-heat-is-up-on-vip"]

      Exec["all-heat-nodes-are-up"]
      ->
<<<<<<< HEAD
      quickstack::pacemaker::resource::service {"openstack-heat-api-cfn":
=======
      quickstack::pacemaker::resource::lsb {"openstack-heat-api-cfn":
        group => "$heat_cfn_group",
>>>>>>> Updating astapor for ICE HOUSE
        clone => true,
        options => 'start-delay=10s',
      }
      ->
      quickstack::pacemaker::constraint::base { 'heat-api-cfn-constr' :
        constraint_type => "order",
        first_resource  => "openstack-heat-api-clone",
        second_resource => "openstack-heat-api-cfn-clone",
        first_action    => "start",
        second_action   => "start",
      }
      ->
      quickstack::pacemaker::constraint::colocation { 'heat-api-cfn-colo' :
        source => "openstack-heat-api-cfn-clone",
        target => "openstack-heat-api-clone",
        score => "INFINITY",
      }
    }

    if str2bool_i($heat_cloudwatch_enabled) {
      Exec["all-heat-nodes-are-up"]
      ->
<<<<<<< HEAD
      quickstack::pacemaker::resource::service {"openstack-heat-api-cloudwatch":
=======
      quickstack::pacemaker::resource::lsb {"openstack-heat-api-cloudwatch":
        group => "$heat_group",
>>>>>>> Updating astapor for ICE HOUSE
        clone => true,
        options => 'start-delay=10s',
      }
      if str2bool_i($heat_cfn_enabled) {
        Quickstack::Pacemaker::Resource::Service['openstack-heat-api-cfn'] ->
        Quickstack::Pacemaker::Resource::Service['openstack-heat-api-cloudwatch'] ->
        quickstack::pacemaker::constraint::base { 'heat-cfn-cloudwatch-constr' :
          constraint_type => "order",
          first_resource  => "openstack-heat-api-cfn-clone",
          second_resource => "openstack-heat-api-cloudwatch-clone",
          first_action    => "start",
          second_action   => "start",
        }
        ->
        quickstack::pacemaker::constraint::colocation { 'heat-cfn-cloudwatch-colo' :
          source => "openstack-heat-api-cloudwatch-clone",
          target => "openstack-heat-api-cfn-clone",
          score => "INFINITY",
        }
        ->
        quickstack::pacemaker::constraint::base { 'heat-cloudwatch-engine-constr' :
          constraint_type => "order",
          first_resource  => "openstack-heat-api-cloudwatch-clone",
          second_resource => "openstack-heat-engine",
          first_action    => "start",
          second_action   => "start",
        }
      }
    }
  }
}
