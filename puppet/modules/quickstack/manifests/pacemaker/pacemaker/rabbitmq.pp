class quickstack::pacemaker::rabbitmq (
  $haproxy_timeout       = '120s',
  $inet_dist_listen      = '35672'
) {

  include quickstack::pacemaker::common

  if (map_params('include_rabbitmq') == 'true') {
    $amqp_group = map_params("amqp_group")
    $amqp_username = map_params("amqp_username")
    $amqp_password = map_params("amqp_password")

    class {'::quickstack::firewall::amqp':
      ports => [ map_params("amqp_port"), "${inet_dist_listen}", 4369 ]
    }

    class {"::rabbitmq":
      config_kernel_variables  => {'inet_dist_listen_min' => "${inet_dist_listen}",
                                   'inet_dist_listen_max' => "${inet_dist_listen}"},
      wipe_db_on_cookie_change => true,
      config_cluster           => true,
      cluster_nodes            => map_params("lb_backend_server_names"),
      node_ip_address          => map_params("local_bind_addr"),
      port                     => map_params("amqp_port"),
      default_user             => $amqp_username,
      default_pass             => $amqp_password,
      admin_enable             => false,
      package_provider         => "yum",
      package_source           => undef,
      manage_repos             => false,
    }

    class {'::quickstack::load_balancer::amqp':
      frontend_host        => map_params("amqp_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
      port                 => map_params("amqp_port"),
      backend_port         => map_params("amqp_port"),
      timeout              => $haproxy_timeout,
    }

    Class['::quickstack::firewall::amqp'] ->
    Class['::rabbitmq'] ->

    exec {"rabbit-mirrored-queues":
      command => '/usr/sbin/rabbitmqctl set_policy HA \'^(?!amq\.).*\' \'{"ha-mode": "all"}\'',
      unless  => '/usr/sbin/rabbitmqctl list_policies | grep -q HA'
    } ->
    Class['::quickstack::pacemaker::common'] ->

    # below creates just one vip (not three)
    quickstack::pacemaker::vips { "$amqp_group":
      public_vip  => map_params("amqp_vip"),
      private_vip => map_params("amqp_vip"),
      admin_vip   => map_params("amqp_vip"),
    } ->
    Class['::quickstack::load_balancer::amqp'] ->

    exec {"pcs-rabbitmq-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property rabbitmq"
    } ->
    exec {"all-rabbitmq-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include rabbitmq",
    } ->
    quickstack::pacemaker::resource::service { 'rabbitmq-server':
      monitor_params => {"start-delay" => "35s"},
      clone          => true,
    }
  }
}
