class quickstack::pacemaker::nova (
  $auto_assign_floating_ip    = 'true',
  $db_name                    = 'nova',
  $db_user                    = 'nova',
  $default_floating_pool      = 'nova',
  $force_dhcp_release         = 'false',
  $image_service              = 'nova.image.glance.GlanceImageService',
  $memcached_port             = '11211',
  $multi_host                 = 'true',
  $neutron_metadata_proxy_secret,
  $qpid_heartbeat             = '60',
  $rpc_backend                = 'nova.openstack.common.rpc.impl_kombu',
  $scheduler_host_subset_size = '30',
  $ram_allocation_ratio         = '1.5',
  $cpu_allocation_ratio         = '16',
  $verbose                    = 'false',
) {

  include quickstack::pacemaker::common

  if (str2bool_i(map_params('include_nova'))) {
    $nova_private_vip = map_params("nova_private_vip")
    $pcmk_nova_group = map_params("nova_group")
    $memcached_ips =  map_params("lb_backend_server_addrs")
    $memcached_servers = split(
      inline_template('<%= @memcached_ips.map {
        |x| x+":"+@memcached_port }.join(",") %>'),
        ','
    )
    # TODO: extract this into a helper function
    if ($::pcs_setup_nova ==  undef or
        !str2bool_i("$::pcs_setup_nova")) {
      $_enabled = true
    } else {
      $_enabled = false
    }
    Exec['i-am-nova-vip-OR-nova-is-up-on-vip'] -> Exec['nova-db-sync']
    if (str2bool_i(map_params('include_mysql'))) {
      Anchor['galera-online'] -> Exec['i-am-nova-vip-OR-nova-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_keystone'))) {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-nova-vip-OR-nova-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_swift'))) {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-nova-vip-OR-nova-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_glance'))) {
      Exec['all-glance-nodes-are-up'] -> Exec['i-am-nova-vip-OR-nova-is-up-on-vip']
    }

    class {"::quickstack::load_balancer::nova":
      frontend_pub_host    => map_params("nova_public_vip"),
      frontend_priv_host   => map_params("nova_private_vip"),
      frontend_admin_host  => map_params("nova_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "$pcmk_nova_group":
      public_vip  => map_params("nova_public_vip"),
      private_vip => map_params("nova_private_vip"),
      admin_vip   => map_params("nova_admin_vip"),
    }
    ->
    exec {"i-am-nova-vip-OR-nova-is-up-on-vip":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash i_am_vip $nova_private_vip || /tmp/ha-all-in-one-util.bash property_exists nova",
      unless    => "/tmp/ha-all-in-one-util.bash i_am_vip $nova_private_vip || /tmp/ha-all-in-one-util.bash property_exists nova",
    }
    ->
    class { '::quickstack::nova':
      admin_password                => map_params("nova_user_password"),
      auth_host                     => map_params("keystone_admin_vip"),
      auto_assign_floating_ip       => $auto_assign_floating_ip,
      bind_address                  => map_params("local_bind_addr"),
      db_host                       => map_params("db_vip"),
      db_name                       => $db_name,
      db_password                   => map_params("nova_db_password"),
      db_user                       => $db_user,
      max_retries                   => '-1',
      default_floating_pool         => $default_floating_pool,
      enabled                       => $_enabled,
      force_dhcp_release            => $force_dhcp_release,
      glance_host                   => map_params("glance_private_vip"),
      glance_port                   => "${::quickstack::load_balancer::glance::api_port}",
      image_service                 => $image_service,
      manage_service                => $_enabled,
      memcached_servers             => $memcached_servers,
      multi_host                    => $multi_host,
      neutron                       => str2bool_i(map_params("neutron")),
      neutron_metadata_proxy_secret => map_params("neutron_metadata_proxy_secret"),
      qpid_heartbeat                => $qpid_heartbeat,
      amqp_hostname                 => map_params("amqp_vip"),
      amqp_port                     => map_params("amqp_port"),
      amqp_username                 => map_params("amqp_username"),
      amqp_password                 => map_params("amqp_password"),
      rabbit_hosts                  => map_params("rabbitmq_hosts"),
      rpc_backend                   => amqp_backend('nova', map_params('amqp_provider')),
      scheduler_host_subset_size    => $scheduler_host_subset_size,
      ram_allocation_ratio          => $ram_allocation_ratio,
      cpu_allocation_ratio          => $cpu_allocation_ratio,
      verbose                       => $verbose,
    }
    ->
    exec {"pcs-nova-server-set-up":
      command => "/usr/sbin/pcs property set nova=running --force",
    } ->
    exec {"pcs-nova-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property nova"
    } ->
    exec {"all-nova-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include nova",
    }
    ->
    quickstack::pacemaker::resource::generic {
      [ 'nova-consoleauth',
        'nova-novncproxy',
        'nova-api',
        'nova-scheduler',
        'nova-conductor' ]:
      resource_name_prefix => 'openstack-',
      clone_opts           => '',
      operation_opts       => 'monitor start-delay=10s',
    }
    ->
    quickstack::pacemaker::constraint::base { 'nova-console-vnc-constr' :
      constraint_type => "order",
      first_resource  => "nova-consoleauth-clone",
      second_resource => "nova-novncproxy-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'nova-console-vnc-colo' :
      source => "nova-novncproxy-clone",
      target => "nova-consoleauth-clone",
      score => "INFINITY",
    }
    ->
    quickstack::pacemaker::constraint::base { 'nova-vnc-api-constr' :
      constraint_type => "order",
      first_resource  => "nova-novncproxy-clone",
      second_resource => "nova-api-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'nova-vnc-api-colo' :
      source => "nova-api-clone",
      target => "nova-novncproxy-clone",
      score => "INFINITY",
    }
    ->
    quickstack::pacemaker::constraint::base { 'nova-api-scheduler-constr' :
      constraint_type => "order",
      first_resource  => "nova-api-clone",
      second_resource => 'nova-scheduler-clone',
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'nova-api-scheduler-colo' :
      source => 'nova-scheduler-clone',
      target => "nova-api-clone",
      score => "INFINITY",
    }
    ->
    quickstack::pacemaker::constraint::base { 'nova-scheduler-conductor-constr' :
      constraint_type => "order",
      first_resource  => 'nova-scheduler-clone',
      second_resource => "nova-conductor-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'nova-conductor-scheduler-colo' :
      source => 'nova-scheduler-clone',
      target => "nova-conductor-clone",
      score => "INFINITY",
    }
    ->
    Anchor['pacemaker ordering constraints begin']
  }
}
