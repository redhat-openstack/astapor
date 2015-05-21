class quickstack::pacemaker::galera (
  $limit_no_file            ="16384",
  $max_connections         = "1024",
  $mysql_root_password     = '',
  $open_files_limit        = '-1',
  $galera_monitor_username = 'monitor_user',
  $galera_monitor_password = 'monitor_pass',
  $wsrep_cluster_name      = 'galera_cluster',
  $wsrep_cluster_members   = [],
  $wsrep_sst_method        = 'rsync',
  $wsrep_sst_username      = 'sst_user',
  $wsrep_sst_password      = 'sst_pass',
  $wsrep_ssl               = true,
  $wsrep_ssl_key           = '/etc/pki/galera/galera.key',
  $wsrep_ssl_cert          = '/etc/pki/galera/galera.crt',
) {

  include quickstack::pacemaker::common

  if (str2bool_i(map_params('include_mysql'))) {
    $galera_vip = map_params("db_vip")

    # TODO: extract this into a helper function
    if ($::pcs_setup_galera ==  undef or
        !str2bool_i("$::pcs_setup_galera")) {
      $_enabled = true
      $_ensure = 'running'
    } else {
      $_enabled = false
      $_ensure = undef
    }

    # defined for galera.cnf template
    $wsrep_provider         = '/usr/lib64/galera/libgalera_smm.so'
    $wsrep_bind_address     = map_params("pcmk_bind_addr")
    if $wsrep_ssl {
      $wsrep_provider_options = wsrep_options({
        'socket.ssl'      => $wsrep_ssl,
        'socket.ssl_key'  => $wsrep_ssl_key,
        'socket.ssl_cert' => $wsrep_ssl_cert,
      })
    } else {
      $wsrep_provider_options = wsrep_options({
        'socket.ssl'      => $wsrep_ssl,
      })
    }
    $wsrep_debug = 0

    Exec['all-memcached-nodes-are-up'] -> Class['quickstack::firewall::galera']

    class {"::quickstack::load_balancer::galera":
      frontend_pub_host    => map_params("db_vip"),
      backend_server_names => map_params("pcmk_server_names"),
      backend_server_addrs => map_params("pcmk_server_addrs"),
    }

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "galera":
      public_vip  => map_params("db_vip"),
      private_vip => map_params("db_vip"),
      admin_vip   => map_params("db_vip"),
    } ->
    class {'::quickstack::firewall::galera':}

    # if bootstrap, set up mariadb on all nodes
    if str2bool_i($::galera_bootstrap_ok) {
      Class ['::quickstack::firewall::galera'] ->
      exec {"haproxy resource exists":
        timeout   => 3600,
        tries     => 360,
        try_sleep => 10,
        command   => "/usr/sbin/pcs resource show haproxy-clone",
      } ->
      exec{'disable haproxy during init mysql setup':
        # it's ok to run this on all nodes, additional calls are no-ops        
        command => '/usr/sbin/pcs resource disable haproxy'
      } ->
      class { 'mysql::server':
        #manage_config_file => false,
        #config_file => $mysql_server_config_file,
        package_name => 'mariadb-galera-server',
        override_options => {
        'mysqld' => {
          'bind-address' => map_params("pcmk_bind_addr"),
          'default_storage_engine' => "InnoDB",
          # maybe below?
          max_connections => $max_connections ,
          open_files_limit => $open_files_limit ,
          query_cache_size => '0',
          },
        },
        root_password => $mysql_root_password,
        #  notify => Service['xinetd'],
        #require => Package['mariadb-server'], ? maybe
      }
      ->
      class {"::mysql::server::account_security": }
      ->
      mysql_user { "$galera_monitor_username@localhost":
        ensure        => present,
        password_hash => mysql_password($galera_monitor_password),
      }
      ->
      class {"::quickstack::galera::db":
        keystone_db_password => map_params("keystone_db_password"),
        glance_db_password   => map_params("glance_db_password"),
        nova_db_password     => map_params("nova_db_password"),
        cinder_db_password   => map_params("cinder_db_password"),
        heat_db_password     => map_params("heat_db_password"),
        neutron_db_password  => map_params("neutron_db_password"),
      }
      ->
      file { '/etc/sysconfig/clustercheck' :
        ensure  => file,
        content => "MYSQL_USERNAME=${galera_monitor_username}\n
                    MYSQL_PASSWORD=${galera_monitor_password}\n
                    MYSQL_HOST=localhost\n
                    MYSQL_PORT=3306",
      }
      ->
      xinetd::service { 'galera-monitor' :
        port           => '9200',
        server         => '/usr/bin/clustercheck',
        per_source     => 'UNLIMITED',
        log_on_success => '',
        log_on_failure => 'HOST',
        flags          => 'REUSE',
        service_type   => 'UNLISTED',
        user           => 'root',
        group          => 'root',
        require        => File['/etc/sysconfig/clustercheck'],
      }
      ->
      exec {'stop mariadb after one-time initial start':
        command => '/usr/sbin/service mariadb stop',
      }
      ->
      exec {'disable mariadb after one-time initial start':
        command => '/usr/bin/systemctl disable mariadb',
      }
      ->
      Exec['pcs-mysqlinit-server-setup']
      Mysql_grant <| |> -> Exec["pcs-mysqlinit-server-setup"]
      
      Exec["all-mysqlinit-nodes-are-up"] ->
      Exec['galera-online-cmd'] ->
      exec{'enable haproxy after galera-online':
        # it's ok to run this on all nodes, additional calls are no-ops        
        command => '/usr/sbin/pcs resource enable haproxy'
      } ->
      Anchor['galera-online']
    }
    Class ['::quickstack::firewall::galera'] ->
    file { '/etc/my.cnf.d/galera.cnf':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template('galera/wsrep.cnf.erb'),
    } ->
    Exec['pcs-mysqlinit-server-setup']

    if str2bool_i("$wsrep_ssl") {
      File['/etc/my.cnf.d/galera.cnf'] ->
      class { "::quickstack::pacemaker::rsync::galera":
        cluster_control_ip => map_params("cluster_control_ip"),
      } ->
      Exec['pcs-mysqlinit-server-setup']
    }

    exec {"pcs-mysqlinit-server-setup":
      command => "/usr/sbin/pcs property set mysqlinit=running --force",
    } ->
    exec {"pcs-mysqlinit-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property mysqlinit"
    } ->
    exec {"all-mysqlinit-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include mysqlinit",
    }
    ->
    quickstack::pacemaker::resource::galera {'galera':
      gcomm_addrs   => map_params("pcmk_server_names"),
      limit_no_file => $limit_no_file,
    }
    ->
    # one last clustercheck to make sure service is up
    exec {"galera-online-cmd":
      timeout   => 3600,
      tries     => 60,
      try_sleep => 60,
      environment => ["AVAILABLE_WHEN_READONLY=0"],
      command => '/usr/bin/clustercheck >/dev/null',
    }
    ->
    anchor{'galera-online':}
    ->
    Anchor['pacemaker ordering constraints begin']

    # in the bootstrap case, make sure pacemaker galera resource
    # has been created before the final "galera-online" check
    if str2bool_i($::galera_bootstrap_ok) {
      Quickstack::Pacemaker::Resource::Galera['galera'] ->
      exec {"wait-for-pacemaker-galera-resource-existence":
        timeout   => 3600,
        tries     => 59,
        try_sleep => 60,
        command    => '/usr/sbin/pcs resource show galera && /bin/sleep 60',
      } ->
      Exec['galera-online-cmd']
    }
  }
}
