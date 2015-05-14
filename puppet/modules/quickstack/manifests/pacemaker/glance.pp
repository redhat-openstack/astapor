class quickstack::pacemaker::glance (
  $sql_idle_timeout         = '3600',
  $db_ssl                   = false,
  $db_ssl_ca                = undef,
  $db_user                  = 'glance',
  $db_name                  = 'glance',
  $backend                  = 'file',
  # this manifest is responsible for mounting the 'file' $backend
  # through pacemaker
  $pcmk_fs_manage           = 'true',
  # if $backend is 'file' and $pcmk_fs_manage is true,
  # then make sure other pcmk_fs_ params are correct
  $pcmk_fs_options          = '',
  $pcmk_fs_type             = 'nfs',
  $pcmk_fs_device           = '/shared/storage/device',
  $pcmk_fs_dir              = '/var/lib/glance/images/',
  # if $backend is 'swift' *and* swift is run on the same local
  # pacemaker cluster (as opposed to swift proxies being remote)
  $pcmk_swift_is_local      = true,
  $rbd_store_user           = 'images',
  $rbd_store_pool           = 'images',
  $swift_store_user         = '',
  $swift_store_key          = '',
  $swift_store_auth_address = 'http://127.0.0.1:5000/v2.0/',
  $verbose                  = false,
  $debug                    = false,
  $use_syslog               = false,
  $log_facility             = 'LOG_USER',
  $filesystem_store_datadir = '/var/lib/glance/images/',
) {

  include quickstack::pacemaker::common

  if (str2bool_i(map_params('include_glance'))) {
    $glance_private_vip = map_params("glance_private_vip")
    $pcmk_glance_group = map_params("glance_group")

    # TODO: extract this into a helper function
    if ($::pcs_setup_glance ==  undef or
        !str2bool_i("$::pcs_setup_glance")) {
      $_enabled = true
    } else {
      $_enabled = false
    }

    Exec['i-am-glance-vip-OR-glance-is-up-on-vip'] -> Service['glance-api']-> Exec['pcs-glance-server-set-up']
    Exec['i-am-glance-vip-OR-glance-is-up-on-vip'] -> Service['glance-registry'] -> Exec['pcs-glance-server-set-up']
    Exec['i-am-glance-vip-OR-glance-is-up-on-vip'] -> Exec<| title == 'glance-manage db_sync'|> ->
    Exec['pcs-glance-server-set-up']

    if (str2bool_i(map_params('include_mysql'))) {
      Anchor['galera-online'] -> Exec['i-am-glance-vip-OR-glance-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_keystone'))) {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-glance-vip-OR-glance-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_swift'))) {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-glance-vip-OR-glance-is-up-on-vip']
    }

    if($backend == 'swift') {
      # TODO move to params.pp once swift is added
      if str2bool_i("$pcmk_swift_is_local") {
        Class['::quickstack::pacemaker::swift'] ->
        Class['::quickstack::glance']
      }
    } elsif ($backend == 'file') {
      if str2bool_i("$pcmk_fs_manage") {
        if ($pcmk_fs_type == 'nfs') {
          include ::quickstack::nfs_common
          Package['nfs-utils'] -> Exec['stonith-setup-complete']
        }
        Exec['stonith-setup-complete']
        ->
        quickstack::pacemaker::resource::filesystem { "glance-fs":
          device       => $pcmk_fs_device,
          directory    => $pcmk_fs_dir,
          fstype       => $pcmk_fs_type,
          fsoptions    => $pcmk_fs_options,
          clone_params => '',
        }
        ->
        Class['::quickstack::glance']

        Class['::quickstack::pacemaker::common'] ->
        Quickstack::Pacemaker::Resource::Filesystem["glance-fs"]
      }
    }

    class {"::quickstack::load_balancer::glance":
      frontend_pub_host    => map_params("glance_public_vip"),
      frontend_priv_host   => map_params("glance_private_vip"),
      frontend_admin_host  => map_params("glance_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    Class['::quickstack::pacemaker::common']
    ->
    # assuming openstack-glance-api and openstack-glance-registry
    # always have same vip's for now
    quickstack::pacemaker::vips { "$pcmk_glance_group":
      public_vip  => map_params("glance_public_vip"),
      private_vip => map_params("glance_private_vip"),
      admin_vip   => map_params("glance_admin_vip"),
    }
    ->
    exec {"i-am-glance-vip-OR-glance-is-up-on-vip":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash i_am_vip $glance_private_vip || /tmp/ha-all-in-one-util.bash property_exists glance",
      unless   => "/tmp/ha-all-in-one-util.bash i_am_vip $glance_private_vip || /tmp/ha-all-in-one-util.bash property_exists glance",
    } ->
    class { 'quickstack::glance':
      user_password            => map_params("glance_user_password"),
      db_password              => map_params("glance_db_password"),
      db_host                  => map_params("db_vip"),
      keystone_host            => map_params("keystone_admin_vip"),
      sql_idle_timeout         => $sql_idle_timeout,
      registry_host            => map_params("local_bind_addr"),
      bind_host                => map_params("local_bind_addr"),
      db_ssl                   => $db_ssl,
      db_ssl_ca                => $db_ssl_ca,
      db_user                  => $db_user,
      db_name                  => $db_name,
      max_retries              => '-1',
      backend                  => $backend,
      rbd_store_user           => $rbd_store_user,
      rbd_store_pool           => $rbd_store_pool,
      swift_store_user         => $swift_store_user,
      swift_store_key          => $swift_store_key,
      swift_store_auth_address => $swift_store_auth_address,
      verbose                  => $verbose,
      debug                    => $debug,
      use_syslog               => $use_syslog,
      log_facility             => $log_facility,
      enabled                  => $_enabled,
      manage_service           => $_enabled,
      filesystem_store_datadir => $filesystem_store_datadir,
      amqp_host                => map_params("amqp_vip"),
      amqp_port                => map_params("amqp_port"),
      amqp_username            => map_params("amqp_username"),
      amqp_password            => map_params("amqp_password"),
      amqp_provider            => map_params("amqp_provider"),
      rabbit_hosts             => map_params("rabbitmq_hosts"),
    }
    ->
    exec {"pcs-glance-server-set-up":
      command => "/usr/sbin/pcs property set glance=running --force",
    } ->
    exec {"pcs-glance-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property glance"
    } ->
    exec {"all-glance-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include glance",
    } ->
    quickstack::pacemaker::resource::generic {'glance-registry':
      clone_opts    => '',
      resource_name => "openstack-glance-registry",
    } ->
    quickstack::pacemaker::resource::generic {'glance-api':
      clone_opts    => '',
      resource_name => "openstack-glance-api",
    }

    if str2bool_i("$pcmk_fs_manage") {
      $glance_fs_resource_name = delete("fs-${$pcmk_fs_dir}", '/')
      quickstack::pacemaker::constraint::base { 'glance-fs-registry-constr' :
        constraint_type => "order",
        first_resource  => "${glance_fs_resource_name}-clone",
        second_resource => "glance-registry-clone",
        first_action    => "start",
        second_action   => "start",
      }
      ->
      quickstack::pacemaker::constraint::colocation { 'glance-fs-registry-colo' :
        source => "glance-registry-clone",
        target => "${glance_fs_resource_name}-clone",
        score => "INFINITY",
      }
      Quickstack::Pacemaker::Resource::Filesystem['glance-fs'] ->
      Quickstack::Pacemaker::Resource::Generic['glance-registry'] ->
      Quickstack::Pacemaker::Constraint::Base['glance-fs-registry-constr']
    }

    Quickstack::Pacemaker::Resource::Generic['glance-api']
    ->
    quickstack::pacemaker::constraint::base { 'glance-registry-api-constr' :
      constraint_type => "order",
      first_resource  => "glance-registry-clone",
      second_resource => "glance-api-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'glance-registry-api-colo' :
      source => "glance-api-clone",
      target => "glance-registry-clone",
      score => "INFINITY",
    }
    ->
    Anchor['pacemaker ordering constraints begin']

    if ($backend == 'rbd') {
      include ::quickstack::ceph::client_packages
      include ::quickstack::pacemaker::ceph_config
      include ::quickstack::firewall::ceph_mon

      Class['quickstack::firewall::ceph_mon'] ->
      Exec['i-am-glance-vip-OR-glance-is-up-on-vip']

      Class['quickstack::pacemaker::ceph_config'] ->
      Class['quickstack::ceph::client_packages'] ->
      Exec['i-am-glance-vip-OR-glance-is-up-on-vip']
    }
  }
}
