class quickstack::pacemaker::cinder(
  $db_name                = 'cinder',
  $db_user                = 'cinder',

  $volume                 = false,
  $backend_eqlx           = false,
  $backend_eqlx_name      = ['eqlx'],
  $backend_glusterfs      = false,
  $backend_glusterfs_name = 'glusterfs',
  $backend_iscsi          = false,
  $backend_iscsi_name     = 'iscsi',
  $backend_nfs            = false,
  $backend_nfs_name       = 'nfs',
  $backend_rbd            = false,
  $backend_rbd_name       = 'rbd',

  $multiple_backends      = false,
  $create_volume_types    = true,

  $glusterfs_shares       = [],

  $nfs_shares             = [],
  $nfs_mount_options      = undef,

  $san_ip                 = [''],
  $san_login              = ['grpadmin'],
  $san_password           = [''],
  $san_thin_provision     = [true],
  $eqlx_group_name        = ['group-0'],
  $eqlx_pool              = ['default'],
  $eqlx_use_chap          = [false],
  $eqlx_chap_login        = ['chapadmin'],
  $eqlx_chap_password     = [''],

  $rbd_pool               = 'volumes',
  $rbd_ceph_conf          = '/etc/ceph/ceph.conf',
  $rbd_flatten_volume_from_snapshot
                          = false,
  $rbd_max_clone_depth    = '5',
  $rbd_user               = 'volumes',
  $rbd_secret_uuid        = '',

  $db_ssl                 = false,
  $db_ssl_ca              = undef,

  $rpc_backend            = 'cinder.openstack.common.rpc.impl_kombu',
  $qpid_heartbeat         = '60',

  $use_syslog             = false,
  $log_facility           = 'LOG_USER',

  $enabled                = true,
  $debug                  = false,
  $verbose                = false,
) {

  include ::quickstack::pacemaker::common

  if (str2bool_i(map_params('include_cinder'))) {

    include ::quickstack::pacemaker::amqp

    $cinder_user_password = map_params("cinder_user_password")
    $cinder_private_vip   = map_params("cinder_private_vip")
    $cinder_admin_vip     = map_params("cinder_admin_vip")
    $pcmk_cinder_group    = map_params("cinder_group")
    $db_host              = map_params("db_vip")
    $db_password          = map_params("cinder_db_password")
    $glance_host          = map_params("glance_admin_vip")
    $keystone_host        = map_params("keystone_admin_vip")

    # TODO: extract this into a helper function
    if ($::pcs_setup_cinder ==  undef or
        !str2bool_i("$::pcs_setup_cinder")) {
      $_enabled = true
    } else {
      $_enabled = false
    }

    Exec['i-am-cinder-vip-OR-cinder-is-up-on-vip'] -> Exec<| title =='cinder-manage db_sync'|> -> Exec['pcs-cinder-server-set-up']
    if (str2bool_i(map_params('include_mysql'))) {
      Exec['galera-online'] -> Exec['i-am-cinder-vip-OR-cinder-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_keystone'))) {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-cinder-vip-OR-cinder-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_swift'))) {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-cinder-vip-OR-cinder-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_glance'))) {
      Exec['all-glance-nodes-are-up'] -> Exec['i-am-cinder-vip-OR-cinder-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_nova'))) {
      Exec['all-nova-nodes-are-up'] -> Exec['i-am-cinder-vip-OR-cinder-is-up-on-vip']
    }

    class {"::quickstack::load_balancer::cinder":
      frontend_pub_host    => map_params("cinder_public_vip"),
      frontend_priv_host   => map_params("cinder_private_vip"),
      frontend_admin_host  => map_params("cinder_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    Class['::quickstack::pacemaker::amqp']
    ->
    # assuming openstack-cinder-api and openstack-cinder-scheduler
    # always have same vip's for now
    quickstack::pacemaker::vips { "$pcmk_cinder_group":
      public_vip  => map_params("cinder_public_vip"),
      private_vip => map_params("cinder_private_vip"),
      admin_vip   => map_params("cinder_admin_vip"),
    }
    ->
    exec {"i-am-cinder-vip-OR-cinder-is-up-on-vip":
      timeout => 3600,
      tries => 360,
      try_sleep => 10,
      command => "/tmp/ha-all-in-one-util.bash i_am_vip $cinder_private_vip || /tmp/ha-all-in-one-util.bash property_exists cinder",
      unless => "/tmp/ha-all-in-one-util.bash i_am_vip $cinder_private_vip || /tmp/ha-all-in-one-util.bash property_exists cinder",
    }
    ->
    class {'::quickstack::cinder':
      user_password  => $cinder_user_password,
      bind_host      => map_params('local_bind_addr'),
      db_host        => $db_host,
      db_name        => $db_name,
      db_user        => $db_user,
      db_password    => $db_password,
      max_retries    => '-1',
      db_ssl         => $db_ssl,
      db_ssl_ca      => $db_ssl_ca,
      enabled        => $_enabled,
      glance_host    => $glance_host,
      keystone_host  => $keystone_host,
      manage_service => $_enabled,
      rpc_backend    => amqp_backend('cinder', map_params('amqp_provider')),
      amqp_host      => map_params('amqp_vip'),
      amqp_port      => map_params('amqp_port'),
      amqp_username  => map_params('amqp_username'),
      amqp_password  => map_params('amqp_password'),
      qpid_heartbeat => $qpid_heartbeat,
      use_syslog     => $use_syslog,
      log_facility   => $log_facility,
      debug          => $debug,
      verbose        => $verbose,
    }

    Class['::quickstack::cinder'] ->
    Service[openstack-cinder-api] ->
    Service[openstack-cinder-scheduler] ->
    exec {"pcs-cinder-server-set-up":
      command => "/usr/sbin/pcs property set cinder=running --force",
    } ->
    exec {"pcs-cinder-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property cinder"
    } ->
    exec {"all-cinder-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include cinder",
    } ->
    quickstack::pacemaker::resource::service {'openstack-cinder-api':
      clone => true,
      options => 'start-delay=10s',
    } ->
    quickstack::pacemaker::resource::service {'openstack-cinder-scheduler':
      clone => true,
      options => 'start-delay=10s',
    } ->
    quickstack::pacemaker::constraint::base { 'cinder-api-scheduler-constr' :
      constraint_type => "order",
      first_resource  => "openstack-cinder-api-clone",
      second_resource => "openstack-cinder-scheduler-clone",
      first_action    => "start",
      second_action   => "start",
    } ->
    quickstack::pacemaker::constraint::colocation { 'cinder-api-scheduler-colo' :
      source => "openstack-cinder-scheduler-clone",
      target => "openstack-cinder-api-clone",
      score => "INFINITY",
    } ->
    Anchor['pacemaker ordering constraints begin']

    if str2bool_i("$volume") {
      # FIXME(jistr): remove the host override
      # https://bugs.launchpad.net/cinder/+bug/1322190
      cinder_config {
        'DEFAULT/host': value => 'ha-controller';
      }

      Class['::quickstack::cinder']
      ->
      class {'::quickstack::cinder_volume':
        backend_glusterfs      => $backend_glusterfs,
        backend_glusterfs_name => $backend_glusterfs_name,
        backend_iscsi          => $backend_iscsi,
        backend_iscsi_name     => $backend_iscsi_name,
        backend_nfs            => $backend_nfs,
        backend_nfs_name       => $backend_nfs_name,
        backend_eqlx           => $backend_eqlx,
        backend_eqlx_name      => $backend_eqlx_name,
        backend_rbd            => $backend_rbd,
        backend_rbd_name       => $backend_rbd_name,
        multiple_backends      => $multiple_backends,
        iscsi_bind_addr        => map_params('local_bind_addr'),
        glusterfs_shares       => $glusterfs_shares,
        nfs_shares             => $nfs_shares,
        nfs_mount_options      => $nfs_mount_options,
        san_ip                 => $san_ip,
        san_login              => $san_login,
        san_password           => $san_password,
        san_thin_provision     => $san_thin_provision,
        eqlx_group_name        => $eqlx_group_name,
        eqlx_pool              => $eqlx_pool,
        eqlx_use_chap          => $eqlx_use_chap,
        eqlx_chap_login        => $eqlx_chap_login,
        eqlx_chap_password     => $eqlx_chap_password,
        rbd_pool               => $rbd_pool,
        rbd_ceph_conf          => $rbd_ceph_conf,
        rbd_flatten_volume_from_snapshot
                               => $rbd_flatten_volume_from_snapshot,
        rbd_max_clone_depth    => $rbd_max_clone_depth,
        rbd_user               => $rbd_user,
        rbd_secret_uuid        => $rbd_secret_uuid,
        enabled                => $_enabled,
        manage_service         => $_enabled,
      }
      ->
      Exec['pcs-cinder-server-set-up']

      Exec['all-cinder-nodes-are-up']
      ->
      quickstack::pacemaker::resource::service {'openstack-cinder-volume':
        # FIXME(jistr): set 'clone => true'
        # https://bugs.launchpad.net/cinder/+bug/1322190
        options => 'start-delay=10s',
      }
      ->
      quickstack::pacemaker::constraint::base { 'cinder-scheduler-volume-constr' :
        constraint_type => "order",
        first_resource  => "openstack-cinder-scheduler-clone",
        second_resource => "openstack-cinder-volume",
        first_action    => "start",
        second_action   => "start",
      }
      ->
      quickstack::pacemaker::constraint::colocation { 'cinder-scheduler-volume-colo' :
        source => "openstack-cinder-volume",
        target => "openstack-cinder-scheduler-clone",
        score => "INFINITY",
      }
    }

    if str2bool_i("$create_volume_types") and str2bool_i("$multiple_backends") {
      Class['::quickstack::cinder']
      ->
      class {'::quickstack::cinder_volume_types':
        backend_glusterfs      => $backend_glusterfs,
        backend_glusterfs_name => $backend_glusterfs_name,
        backend_iscsi          => $backend_iscsi,
        backend_iscsi_name     => $backend_iscsi_name,
        backend_nfs            => $backend_nfs,
        backend_nfs_name       => $backend_nfs_name,
        backend_eqlx           => $backend_eqlx,
        backend_eqlx_name      => $backend_eqlx_name,
        backend_rbd            => $backend_rbd,
        backend_rbd_name       => $backend_rbd_name,
        os_username            => 'admin',
        os_tenant_name         => $::quickstack::pacemaker::keystone::admin_tenant,
        os_password            => $::quickstack::pacemaker::keystone::admin_password,
        os_auth_url            => "http://${keystone_host}:35357/v2.0/",
        cinder_api_host        => $cinder_admin_vip,
      }
      ->
      Exec['pcs-cinder-server-set-up']
    }

    if (str2bool_i($backend_rbd)) {
      include ::quickstack::ceph::client_packages
      include ::quickstack::pacemaker::ceph_config
      include ::quickstack::firewall::ceph_mon

      Class['quickstack::firewall::ceph_mon'] ->
      Exec['i-am-cinder-vip-OR-cinder-is-up-on-vip']

      # this block just some puppet hackery to install rbd/ceph
      # packages, avoiding a "package" re-declaration (for python-ceph)
      if (str2bool_i(map_params('include_glance'))) {
        include ::quickstack::pacemaker::glance
        if ($::quickstack::pacemaker::glance::backend != 'rbd') {
          package {'python-ceph': } -> Class['quickstack::ceph::client_packages']
        }
      }
      else {
        package {'python-ceph': } -> Class['quickstack::ceph::client_packages']
      }

      Class['quickstack::pacemaker::ceph_config'] ->
      Class['quickstack::ceph::client_packages'] ->
      Exec['i-am-cinder-vip-OR-cinder-is-up-on-vip']
    }
  }
}
