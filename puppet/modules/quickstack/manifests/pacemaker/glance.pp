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
  $pcmk_glance_group        = 'glance',
  $rbd_store_user           = '',
  $rbd_store_pool           = 'images',
  $swift_store_user         = '',
  $swift_store_key          = '',
  $swift_store_auth_address = 'http://127.0.0.1:5000/v2.0/',
  $verbose                  = false,
  $debug                    = false,
  $use_syslog               = false,
  $log_facility             = 'LOG_USER',
  $enabled                  = true,
  $filesystem_store_datadir = '/var/lib/glance/images/',
) {

  include quickstack::pacemaker::common

  if (map_params('include_glance') == 'true' and map_params("db_is_ready")) {
    $glance_private_vip = map_params("glance_private_vip")

    Exec['i-am-glance-vip-OR-glance-is-up-on-vip'] -> Service['glance-api']
    Exec['i-am-glance-vip-OR-glance-is-up-on-vip'] -> Service['glance-registry']
    Exec['i-am-glance-vip-OR-glance-is-up-on-vip'] -> Exec['glance-manage db_sync']

    if (map_params('include_mysql') == 'true') {
       if str2bool_i("$hamysql_is_running") {
         Exec['mysql-has-users'] -> Exec['i-am-glance-vip-OR-glance-is-up-on-vip']
       }
    }
    if (map_params('include_keystone') == 'true') {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-glance-vip-OR-glance-is-up-on-vip']
    }
    if (map_params('include_swift') == 'true') {
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
        Exec['stonith-setup-complete']
        ->
        pacemaker::resource::filesystem { "glance fs":
          device => $pcmk_fs_device,
          directory => $pcmk_fs_dir,
          fstype => $pcmk_fs_type,
          fsoptions => $pcmk_fs_options,
          clone  => true,
        }
        ->
        Class['::quickstack::glance']

        Class['::quickstack::pacemaker::common'] ->
        Pacemaker::Resource::Filesystem["glance fs"]
      }
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
      enabled                  => $enabled,
      filesystem_store_datadir => $filesystem_store_datadir,
      qpid_host                => map_params("qpid_vip"),
      qpid_port                => map_params("qpid_port"),
    }

    Class['::quickstack::glance']
    ->
    class {"::quickstack::load_balancer::glance":
      frontend_pub_host    => map_params("glance_public_vip"),
      frontend_priv_host   => map_params("glance_private_vip"),
      frontend_admin_host  => map_params("glance_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    } ->
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
    pacemaker::resource::lsb {'openstack-glance-api':
      group => "$pcmk_glance_group",
      clone => true,
    }
    ->
    pacemaker::resource::lsb {'openstack-glance-registry':
      group => "$pcmk_glance_group",
      clone => true,
    }
  }
}
