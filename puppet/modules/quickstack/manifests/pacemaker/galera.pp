class quickstack::pacemaker::galera (
  $mysql_root_password     = '',
  $galera_monitor_username = 'monitor_user',
  $galera_monitor_password = 'monitor_pass',
  $wsrep_cluster_name      = 'galera_cluster',
  $wsrep_cluster_members   = [],
  $wsrep_sst_method        = 'rsync',
  $wsrep_sst_username      = 'sst_user',
  $wsrep_sst_password      = 'sst_pass',
  $wsrep_ssl               = false,
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
    $wsrep_bind_address     = map_params("local_bind_addr")
    $wsrep_provider_options = wsrep_options({
      'socket.ssl'      => $wsrep_ssl,
      'socket.ssl_key'  => $wsrep_ssl_key,
      'socket.ssl_cert' => $wsrep_ssl_cert,
    })
    $wsrep_debug = 0

    Exec['all-memcached-nodes-are-up'] -> Exec['galera-bootstrap-OR-galera-property-exists']

    if (has_interface_with("ipaddress", map_params("cluster_control_ip")) and str2bool_i($::galera_bootstrap_ok)) {
      $galera_bootstrap = true
      $galera_test      = "/bin/true"
      $bootstrap        = true  # variable referenced by galera.cnf
    } else {
      $galera_bootstrap = false
      $galera_test     = "/tmp/ha-all-in-one-util.bash property_exists galera"
    }
    class {"::quickstack::load_balancer::galera":
      frontend_pub_host    => map_params("db_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
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
      class { 'mysql::server':
        #manage_config_file => false,
        #config_file => $mysql_server_config_file,
        package_name => 'mariadb-galera-server',
        override_options => {
        'mysqld' => {
          'bind-address' => map_params("local_bind_addr"),
          'default_storage_engine' => "InnoDB",
          # maybe below?
          max_connections => "1024",
          open_files_limit => '-1',
          },
        },
        root_password => $mysql_root_password,
        #  notify => Service['xinetd'],
        #require => Package['mariadb-server'], ? maybe
      }
      ->
      exec {'stop mariadb after one-time initial start':
        command => '/usr/sbin/service mariadb stop',
      }
      ->
      Exec['galera-bootstrap-OR-galera-property-exists']
    }
    Class ['::quickstack::firewall::galera'] ->
    exec {"galera-bootstrap-OR-galera-property-exists":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => $galera_test,
      unless    => $galera_test,
    } ->
    file { '/etc/my.cnf.d/galera.cnf':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template('galera/wsrep.cnf.erb'),
    } ->
    Exec['pcs-galera-server-setup']

    if str2bool_i("$wsrep_ssl") {
      File['/etc/my.cnf.d/galera.cnf'] ->
      class { "::quickstack::pacemaker::rsync::galera":
        cluster_control_ip => map_params("cluster_control_ip"),
      } ->
      Exec['pcs-galera-server-setup']
    }

    if str2bool_i($::galera_bootstrap_ok) {
      File['/etc/my.cnf.d/galera.cnf'] ->
      exec {'start galera in bootstrap':
        command => "/usr/sbin/service mysqld start"
      }
      ->
      Exec['pcs-galera-server-setup']        
    }
 
    if (has_interface_with("ipaddress", map_params("cluster_control_ip")) and str2bool_i($::galera_bootstrap_ok)) {

      Exec['start galera in bootstrap'] ->
      class {"::quickstack::galera::db":
        keystone_db_password => map_params("keystone_db_password"),
        glance_db_password   => map_params("glance_db_password"),
        nova_db_password     => map_params("nova_db_password"),
        cinder_db_password   => map_params("cinder_db_password"),
        heat_db_password     => map_params("heat_db_password"),
        neutron_db_password  => map_params("neutron_db_password"),
        require              => Exec['start galera in bootstrap'],
      } ->
      Exec['pcs-galera-server-setup']
    }
    exec {"pcs-galera-server-setup":
      command => "/usr/sbin/pcs property set galera=running --force",
    } ->
    exec {"clustercheck-sync":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      environment => ["AVAILABLE_WHEN_READONLY=0"],
      #command   => "/usr/bin/clustercheck >/dev/null",
      # short term substitute since clustercheck always indicates HTTP/1.1 503 Service Unavailable right now
      command => 'echo "SHOW STATUS LIKE \"wsrep_cluster_status%\"" | mysql --defaults-file=/root/.my.cnf | grep -P "\bPrimary\b"',
      path     => '/usr/bin',
    } ->
    exec {"pcs-galera-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property galera"
    } ->
    exec {"all-galera-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include galera",
    }

    if str2bool_i($::galera_bootstrap_ok) {
      Exec['all-galera-nodes-are-up'] ->
      exec {"shutdown-galera-after-bootstrap":
        command   => "/usr/bin/systemctl stop mariadb.service",
      } ->
      exec {"pcs-galera-server-stopped-after-bootstrap":
        command => "/tmp/ha-all-in-one-util.bash update_my_node_property galera-post-bootstrap"
      } ->
      exec {"all-galera-finished-post-bootstrap":
        timeout   => 3600,
        tries     => 360,
        try_sleep => 10,
        command   => "/tmp/ha-all-in-one-util.bash all_members_include galera-post-bootstrap",
      } ->
      Quickstack::Pacemaker::Resource::Service['mysqld']
      if (has_interface_with("ipaddress", map_params("cluster_control_ip"))) {
        $galera_cluster_members_line = inline_template('wsrep_cluster_address="gcomm://<%= @wsrep_cluster_members.join "," %>"')
        Exec['galera-online'] ->
        file_line { 'galera-no-bootstrap':
          path  => '/etc/my.cnf.d/galera.cnf',
          line  => $galera_cluster_members_line,
          match => '^wsrep_cluster_address',
        }
      }
    } else {
      Exec['all-galera-nodes-are-up'] ->
      Quickstack::Pacemaker::Resource::Service['mysqld']
    }

    quickstack::pacemaker::resource::service {'mysqld':
      group          => "$pcmk_galera_group",
      options        => 'start timeout=500s',
      clone          => true,
    } ->
    # one last clustercheck to make sure service is up
    exec {"galera-online":
      timeout   => 3600,
      tries     => 60,
      try_sleep => 60,
      environment => ["AVAILABLE_WHEN_READONLY=0"],
      # if clustercheck fails, it may be that we need to allow
      #  pacemaker to re-attempt to start mysqld on a node, which we
      #  can acheive by cleaning up the resource
      #command   => '/usr/bin/clustercheck || (/usr/sbin/pcs resource cleanup mysqld-clone && /bin/false)',
      # TODO revisit.  use clustercheck if possible
      command => 'echo "SHOW STATUS LIKE \"wsrep_cluster_status%\"" | mysql --defaults-file=/root/.my.cnf | grep -P "\bPrimary\b" || (/usr/sbin/pcs resource cleanup mysqld-clone && /bin/false)',
      path     => '/usr/bin',
    }

    # in the bootstrap case, make sure pacemaker galera resource
    # has been created before the final "galera-online" check
    if str2bool_i($::galera_bootstrap_ok) {
      Quickstack::Pacemaker::Resource::Service['mysqld'] ->
      exec {"wait-for-pacemaker-galera-resource-existence":
        timeout   => 3600,
        tries     => 59,
        try_sleep => 60,
        command    => '/usr/sbin/pcs resource show mysqld-clone && /bin/sleep 60',
      } ->
      Exec['galera-online']
    }
  }
}
