class quickstack::pacemaker::qpid (
  $config_file           = '/etc/qpid/qpidd.conf',
  $package_name          = 'qpid-cpp-server',
  $package_ensure        = present,
  $service_name          = 'qpidd',
  $service_ensure        = running,
  $service_enable        = true,
  $manage_service        = false,
  $backend_port          = '15672',
  $max_connections       = '65530',
  $worker_threads        = '17',
  $connection_backlog    = '65530',
  $realm                 = 'QPID',
  $log_to_file           = 'UNSET',
  $haproxy_timeout       = '120s',
  # perhaps we will expose these to params to ::qpid:server soon
  #$auth                  = 'no',
  #$clustered             = false,
  #$cluster_mechanism     = 'ANONYMOUS',
  #$ssl                   = false,
  #$ssl_package_name      = 'qpid-cpp-server-ssl',
  #$ssl_package_ensure    = present,
  #$ssl_backend_port      = '5671',
  #$ssl_ca                = '/etc/ipa/ca.crt',
  #$ssl_cert              = undef,
  #$ssl_key               = undef,
  #$ssl_database_password = undef,
  #$freeipa               = false,
) {

  include quickstack::pacemaker::common

  if (str2bool_i(map_params('include_amqp')) and
      map_params('amqp_provider') == 'qpid') {
    $amqp_group = map_params("amqp_group")
    $amqp_username = map_params("amqp_username")
    $amqp_password = map_params("amqp_password")

    class {'::quickstack::firewall::amqp':
      ports => [ $backend_port, map_params("amqp_port") ]
    }

    class {'::qpid::server':
      config_file           => $config_file,
      package_name          => $package_name,
      package_ensure        => $package_ensure,
      service_name          => $service_name,
      service_ensure        => $service_ensure,
      service_enable        => $service_enable,
      manage_service        => $manage_service,
      port                  => $backend_port,
      max_connections       => $max_connections,
      worker_threads        => $worker_threads,
      connection_backlog    => $connection_backlog,
      auth => $amqp_username ? {
        ''      => 'no',
        default => 'yes',
      },
      realm                 => 'QPID',
      log_to_file           => $log_to_file,
      clustered             => false,
      ssl                   => false,
    }

    # quoth the puppet language reference,
    # "Empty strings are false; all other strings are true."
    if $amqp_username {
      qpid_user { $amqp_username:
        password  => $amqp_password,
        file      => '/var/lib/qpidd/qpidd.sasldb',
        realm     => 'QPID',
        provider  => 'saslpasswd2',
        require   => Class['qpid::server'],
      }
    }

    class {'::quickstack::load_balancer::amqp':
      frontend_host        => map_params("amqp_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
      port                 => map_params("amqp_port"),
      backend_port         => $backend_port,
      timeout              => $haproxy_timeout,
      extra_listen_options => { 'stick-table' => 'type ip size 2',
                                'stick' => 'on dst'},
    }

    if (str2bool_i(map_params('include_mysql'))) {
      # avoid race condition with galera setup
      Anchor['galera-online'] -> Exec['all-qpid-nodes-are-up']
    }

    Class['::quickstack::firewall::amqp'] ->
    Class['::qpid::server'] ->
    Class['::quickstack::pacemaker::common'] ->

    # below creates just one vip (not three)
    quickstack::pacemaker::vips { "$amqp_group":
      public_vip  => map_params("amqp_vip"),
      private_vip => map_params("amqp_vip"),
      admin_vip   => map_params("amqp_vip"),
    } ->

    exec {"pcs-qpid-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property qpid"
    } ->
    exec {"all-qpid-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include qpid",
    } ->
    quickstack::pacemaker::resource::generic { 'qpidd':
      clone_opts => '',
    } ->
    Anchor['pacemaker ordering constraints begin']
  }
}
