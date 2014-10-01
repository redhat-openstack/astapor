# Quickstack All-In-One class with neutron (OpenStack Networking)
class quickstack::neutron::allinone (
  $admin_email,
  $admin_password,

  $amqp_vip,
  $amqp_password,
  $amqp_provider,
  $amqp_username,
  $amqp_ca,
  $amqp_cert,
  $amqp_key,

  # TODO: Check usage
  $amqp_nssdb_password,

  $ceilometer,
  $ceilometer_admin_vip,
  $ceilometer_private_vip,
  $ceilometer_public_vip,
  $ceilometer_metering_secret,
  $ceilometer_user_password,

  $ceph_cluster_network          = '',
  $ceph_public_network           = '',
  $ceph_fsid                     = '',
  $ceph_images_key               = '',
  $ceph_volumes_key              = '',
  $ceph_mon_host                 = [ ],
  $ceph_mon_initial_members      = [ ],

  $cinder,
  $cinder_admin_vip,
  $cinder_private_vip,
  $cinder_public_vip,
  $cinder_backend_eqlx,
  $cinder_backend_eqlx_name,
  $cinder_backend_gluster,
  $cinder_backend_gluster_name,
  $cinder_backend_iscsi,
  $cinder_backend_iscsi_name,
  $cinder_backend_nfs,
  $cinder_backend_nfs_name,
  $cinder_backend_rbd,
  $cinder_backend_rbd_name,
  $cinder_db_password,
  $cinder_multiple_backends,
  $cinder_gluster_shares,
  $cinder_nfs_shares,
  $cinder_nfs_mount_options,
  $cinder_san_ip,
  $cinder_san_login,
  $cinder_san_password,
  $cinder_san_thin_provision,
  $cinder_eqlx_group_name,
  $cinder_eqlx_pool,
  $cinder_eqlx_use_chap,
  $cinder_eqlx_chap_login,
  $cinder_eqlx_chap_password,
  $cinder_rbd_pool,
  $cinder_rbd_ceph_conf,
  $cinder_rbd_flatten_volume_from_snapshot,
  $cinder_rbd_max_clone_depth,
  $cinder_rbd_user               = 'volumes',
  $cinder_rbd_secret_uuid        = '',
  $cinder_user_password,

  $cisco_nexus_plugin,
  $cisco_vswitch_plugin,
  $cisco_provider_vlan_auto_create,
  $cisco_provider_vlan_auto_trunk,
  $cisco_tenant_network_type,

  $freeipa,

  $glance,
  $glance_admin_vip,
  $glance_private_vip,
  $glance_public_vip,
  $glance_db_password,
  $glance_user_password,
  $glance_backend,
  $glance_backend_rbd            = 'false',
  $glance_rbd_store_user,
  $glance_rbd_store_pool,

  $heat_cfn_admin_vip,
  $heat_cfn_private_vip,
  $heat_cfn_public_vip,

  $heat,
  $heat_admin_vip,
  $heat_private_vip,
  $heat_public_vip,
  $heat_auth_encrypt_key,
  $heat_cloudwatch,
  $heat_db_password,
  $heat_user_password,

  $heat_cfn,
  $heat_cfn_admin_vip,
  $heat_cfn_private_vip,
  $heat_cfn_public_vip,

  $horizon,
  $horizon_vip,
  $horizon_ca,
  $horizon_cert,
  $horizon_key,
  $horizon_secret_key,

  $keystone_admin_vip,
  $keystone_private_vip,
  $keystone_public_vip,
  $keystonerc                    = undef,
  $keystone_admin_token,
  $keystone_db_password,

  $libvirt_images_rbd_pool       = 'volumes',
  $libvirt_images_rbd_ceph_conf  = '/etc/ceph/ceph.conf',
  $libvirt_inject_password       = 'false',
  $libvirt_inject_key            = 'false',
  $libvirt_images_type           = 'rbd',
  $libvirt_kvm_capable,

  $ml2_type_drivers              = ['vxlan', 'flat', 'vlan', 'gre', 'local'],
  $ml2_tenant_network_types      = ['vxlan', 'flat', 'vlan', 'gre'],
  $ml2_mechanism_drivers         = ['openvswitch','l2population'],
  $ml2_flat_networks             = ['*'],
  $ml2_network_vlan_ranges       = ['physnet1:1000:2999'],
  $ml2_tunnel_id_ranges          = ['20:100'],
  $ml2_vxlan_group               = '224.0.0.1',
  $ml2_vni_ranges                = ['10:100'],
  $ml2_security_group            = 'true',
  $ml2_firewall_driver           = 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',

  $mysql_vip,
  $mysql_root_password,
  $mysql_bind_address            = '0.0.0.0',
  $mysql_ca,
  $mysql_cert,
  $mysql_key,

  $neutron,
  $neutron_admin_vip,
  $neutron_agent_lbaas           = false,
  $neutron_agent_fwaas           = false,
  $neutron_private_vip,
  $neutron_public_vip,
  $neutron_auth_tenant           = 'services',
  $neutron_auth_user             = 'neutron',
  $neutron_db_password,
  $neutron_user_password,
  $neutron_core_plugin           = 'neutron.plugins.ml2.plugin.Ml2Plugin',
  $neutron_metadata_proxy_secret,
  $neutron_ext_network_bridge    = '',
  $neutron_database_max_retries  = '',
  $neutron_manage_service        = true,

  $nexus_config,
  $nexus_credentials,

  $nova,
  $nova_admin_vip,
  $nova_private_vip,
  $nova_public_vip,
  $nova_db_password,
  $nova_user_password,

  $ovs_bridge_mappings,
  $ovs_bridge_uplinks,
  $ovs_enable_tunneling,
  $ovs_tunnel_iface              = undef,
  $ovs_tunnel_network            = undef,
  $ovs_tunnel_types,
  $ovs_vlan_ranges,
  $ovs_vxlan_udp_port,
  $ovs_l2_population            = 'True',

  $private_network               = '',
  $private_iface                 = 'eth2',
  $private_ip                    = '',

  $ssl,

  $swift,
  $swift_admin_vip,
  $swift_private_vip,
  $swift_public_vip,
  $swift_shared_secret,
  $swift_admin_password,
  $swift_ringserver_ip           = '192.168.203.1',
  $swift_storage_ips             = ["192.168.203.2","192.168.203.3","192.168.203.4"],
  $swift_storage_device          = 'device1',

  $verbose,
) {

  class {'quickstack::openstack_common': }

  if str2bool_i("$ssl") {
    $qpid_protocol = 'ssl'
    $amqp_port = '5671'
    $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_vip}/nova?ssl_ca=${mysql_ca}"
    $neutron_sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_vip}/neutron?ssl_ca=${mysql_ca}"
    apache::listen { '443': }

    if str2bool_i("$freeipa") {
      certmonger::request_ipa_cert { 'mysql':
        seclib => "openssl",
        principal => "mysql/${mysql_vip}",
        key => $mysql_key,
        cert => $mysql_cert,
        owner_id => 'mysql',
        group_id => 'mysql',
      }
      certmonger::request_ipa_cert { 'horizon':
        seclib => "openssl",
        principal => "horizon/${horizon_vip}",
        key => $horizon_key,
        cert => $horizon_cert,
        owner_id => 'apache',
        group_id => 'apache',
        hostname => $horizon_vip,
      }
      if $amqp_provider == 'rabbitmq' {
        certmonger::request_ipa_cert { 'amqp':
          seclib => "openssl",
          principal => "amqp/${amqp_vip}",
          key => $amqp_key,
          cert => $amqp_cert,
          owner_id => 'rabbitmq',
          group_id => 'rabbitmq',
        }
      }
    } else {
      if $mysql_ca == undef or $mysql_cert == undef or $mysql_key == undef {
        fail('The mysql CA, cert and key are all required.')
      }
      if $amqp_ca == undef or $amqp_cert == undef or $amqp_key == undef {
        fail('The amqp CA, cert and key are all required.')
      }
      if $horizon_ca == undef or $horizon_cert == undef or
        $horizon_key == undef {
        fail('The horizon CA, cert and key are all required.')
      }
    }
  } else {
      $qpid_protocol = 'tcp'
      $amqp_port = '5672'
      $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_vip}/nova"
      $neutron_sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_vip}/neutron"
  }

  ### Controller

  class {'quickstack::db::mysql':
    mysql_root_password  => $mysql_root_password,
    keystone_db_password => $keystone_db_password,
    glance_db_password   => $glance_db_password,
    nova_db_password     => $nova_db_password,
    cinder_db_password   => $cinder_db_password,
    neutron_db_password  => $neutron_db_password,

    # MySQL
    mysql_bind_address     => $mysql_bind_address,
    mysql_account_security => true,
    mysql_ssl              => str2bool_i("$ssl"),
    mysql_ca               => $mysql_ca,
    mysql_cert             => $mysql_cert,
    mysql_key              => $mysql_key,

    allowed_hosts          => ['%',$mysql_vip],
    enabled                => true,

    # Networking
    neutron                => str2bool_i("$neutron"),
  }

  # TODO:
  firewall { '001 mysql incoming':
    proto    => 'tcp',
    dport    => '3306',
    action   => 'accept',
  }

  class {'quickstack::amqp::server':
    amqp_provider => $amqp_provider,
    amqp_host     => $amqp_vip,
    amqp_port     => $amqp_port,
    amqp_username => $amqp_username,
    amqp_password => $amqp_password,
    amqp_ca       => $amqp_ca,
    amqp_cert     => $amqp_cert,
    amqp_key      => $amqp_key,
    ssl           => $ssl,
    freeipa       => $freeipa,
  }

  # TODO: Need to fix quickstack::firewall::amqp
  if str2bool_i("$ssl") {
    class {'quickstack::firewall::amqp':}
  } else {
    firewall { '001 amqp incoming':
      proto    => 'tcp',
      dport    => '5672',
      action   => 'accept',
    }
  }

  class {"::quickstack::keystone::common":
    admin_token                 => $keystone_admin_token,
    bind_host                   => '0.0.0.0',
    db_host                     => $mysql_vip,
    db_password                 => $keystone_db_password,
    db_ssl                      => str2bool_i("$ssl"),
    db_ssl_ca                   => $mysql_ca,
    debug                       => 'false',
    idle_timeout                => '200',
    log_facility                => 'LOG_USER',
    use_syslog                  => 'false',
    verbose                     => str2bool_i("$verbose"),
  } ->
  class {"::quickstack::keystone::endpoints":
    admin_address               => $keystone_admin_vip,
    admin_email                 => $admin_email,
    admin_password              => $admin_password,
    internal_address            => $keystone_private_vip,
    public_address              => $keystone_public_vip,

    ceilometer                  => str2bool_i("$ceilometer"),
    ceilometer_user_password    => $ceilometer_user_password,
    ceilometer_public_address   => $ceilometer_public_vip,
    ceilometer_internal_address => $ceilometer_private_vip,
    ceilometer_admin_address    => $ceilometer_admin_vip,
    cinder                      => str2bool_i("$cinder"),
    cinder_user_password        => $cinder_user_password,
    cinder_public_address       => $cinder_public_vip,
    cinder_internal_address     => $cinder_private_vip,
    cinder_admin_address        => $cinder_admin_vip,
    glance                      => str2bool_i("$glance"),
    glance_user_password        => $glance_user_password,
    glance_public_address       => $glance_public_vip,
    glance_internal_address     => $glance_private_vip,
    glance_admin_address        => $glance_admin_vip,
    heat                        => str2bool_i("$heat"),
    heat_user_password          => $heat_user_password,
    heat_public_address         => $heat_public_vip,
    heat_internal_address       => $heat_private_vip,
    heat_admin_address          => $heat_admin_vip,
    heat_cfn                    => str2bool_i("$heat_cfn"),
    heat_cfn_user_password      => $heat_cfn_user_password,
    heat_cfn_public_address     => $heat_cfn_public_vip,
    heat_cfn_internal_address   => $heat_cfn_private_vip,
    heat_cfn_admin_address      => $heat_cfn_admin_vip,
    neutron                     => str2bool_i("$neutron"),
    neutron_user_password       => $neutron_user_password,
    neutron_public_address      => $neutron_public_vip,
    neutron_internal_address    => $neutron_private_vip,
    neutron_admin_address       => $neutron_admin_vip,
    nova                        => str2bool_i("$nova"),
    nova_user_password          => $nova_user_password,
    nova_public_address         => $nova_public_vip,
    nova_internal_address       => $nova_private_vip,
    nova_admin_address          => $nova_admin_vip,
    swift                       => str2bool_i("$swift"),
    swift_user_password         => $swift_user_password,
    swift_public_address        => $swift_public_vip,
    swift_internal_address      => $swift_public_vip,
    swift_admin_address         => $swift_public_vip,
  }

  class {'quickstack::firewall::keystone':}

  # Glance controller
  if str2bool_i("$glance") {
    class {'quickstack::glance':
      db_host        => $mysql_vip,
      db_ssl         => str2bool_i("$ssl"),
      db_ssl_ca      => $mysql_ca,
      user_password  => $glance_user_password,
      db_password    => $glance_db_password,
      backend        => $glance_backend,
      rbd_store_user => $glance_rbd_store_user,
      rbd_store_pool => $glance_rbd_store_pool,
      require        => Class['quickstack::db::mysql'],
      amqp_host      => $amqp_vip,
      amqp_port      => $amqp_port,
      amqp_username  => $amqp_username,
      amqp_password  => $amqp_password,
      amqp_provider  => $amqp_provider,
    }
  }

  # Nova Controller
  class { '::nova':
    sql_connection     => $nova_sql_connection,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "http://${glance_private_vip}:9292/v1",
    rpc_backend        => amqp_backend('nova', $amqp_provider),
    qpid_hostname      => $amqp_vip,
    qpid_protocol      => $qpid_protocol,
    qpid_port          => $amqp_port,
    qpid_username      => $amqp_username,
    qpid_password      => $amqp_password,
    rabbit_host        => $amqp_vip,
    rabbit_port        => $amqp_port,
    rabbit_userid      => $amqp_username,
    rabbit_password    => $amqp_password,
    rabbit_use_ssl     => str2bool_i("$ssl"),
    verbose            => $verbose,
    require            => Class['quickstack::db::mysql', 'quickstack::amqp::server'],
  }

  if str2bool_i("$neutron") {
    class { '::nova::api':
      enabled           => true,
      admin_password    => $nova_user_password,
      auth_host         => $keystone_private_vip,
      neutron_metadata_proxy_shared_secret => $neutron_metadata_proxy_secret,
    }
  } else {
    class { '::nova::api':
      enabled           => true,
      admin_password    => $nova_user_password,
      auth_host         => $keystone_private_vip,
    }
  }

  class { [ '::nova::scheduler', '::nova::cert', '::nova::consoleauth', '::nova::conductor' ]:
    enabled => true,
  }

  class { '::nova::vncproxy':
    host    => '0.0.0.0',
    enabled => true,
  }

  class {'quickstack::firewall::nova':}

  # Ceilometer controller
  if str2bool_i("$ceilometer") {
    class { 'mongodb::server':
        port => '27017',
    }
    ->
    # FIXME: passwordless connection is insecure, also we might use a
    # way to run mongo on a different host in the future
    class { 'ceilometer::db':
        database_connection => 'mongodb://localhost:27017/ceilometer',
        require             => Service['mongod'],
    }

    class { 'ceilometer':
        metering_secret => $ceilometer_metering_secret,
        qpid_hostname   => $amqp_host,
        qpid_port       => $amqp_port,
        qpid_protocol   => $qpid_protocol,
        qpid_username   => $amqp_username,
        qpid_password   => $amqp_password,
        rabbit_host     => $amqp_host,
        rabbit_port     => $amqp_port,
        rabbit_userid   => $amqp_username,
        rabbit_password => $amqp_password,
        rpc_backend     => amqp_backend('ceilometer', $amqp_provider),
        verbose         => $verbose,
    }

    class { 'ceilometer::collector':
        require => Class['ceilometer::db'],
    }

    class { 'ceilometer::agent::notification':}
    class { 'ceilometer::agent::auth':
        auth_url      => "http://${keystone_private_vip}:35357/v2.0",
        auth_password => $ceilometer_user_password,
    }

    class { 'ceilometer::agent::central':
        enabled => true,
    }

    class { 'ceilometer::alarm::notifier':
    }

    class { 'ceilometer::alarm::evaluator':
    }

    class { 'ceilometer::api':
        keystone_host     => $keystone_private_vip,
        keystone_password => $ceilometer_user_password,
        require             => Service['mongod'],
    }

    class {'quickstack::firewall::ceilometer':}
  }

  if str2bool_i("$swift") {
    class {'quickstack::swift::proxy':
      swift_proxy_host           => $swift_public_vip,
      keystone_host              => $keystone_public_vip,
      swift_admin_password       => $swift_admin_password,
      swift_shared_secret        => $swift_shared_secret,
      swift_storage_ips          => $swift_storage_ips,
      swift_storage_device       => $swift_storage_device,
      swift_ringserver_ip        => $swift_ringserver_ip,
      swift_is_ringserver        => true,
    }

    class {'quickstack::firewall::swift':}
  }

  if str2bool_i("$cinder") {
    class { 'quickstack::cinder':
      user_password => $cinder_user_password,
      db_host       => $mysql_vip,
      db_ssl        => $ssl,
      db_ssl_ca     => $mysql_ca,
      db_password   => $cinder_db_password,
      glance_host   => $glance_private_vip,
      rpc_backend   => amqp_backend('cinder', $amqp_provider),
      amqp_host     => $amqp_vip,
      amqp_port     => $amqp_port,
      amqp_username => $amqp_username,
      amqp_password => $amqp_password,
      qpid_protocol => $qpid_protocol,
      verbose       => $verbose,
    }

    # preserve original behavior - fall back to iscsi
    # https://github.com/redhat-openstack/astapor/blob/7cf25e1022bee08b0c385ae956d4e9e4ade14a9d/puppet/modules/quickstack/manifests/cinder_controller.pp#L85
    if (!str2bool_i("$cinder_backend_gluster") and
        !str2bool_i("$cinder_backend_eqlx") and
        !str2bool_i("$cinder_backend_rbd") and
        !str2bool_i("$cinder_backend_nfs")) {
      $cinder_backend_iscsi_with_fallback = 'true'
    } else {
      $cinder_backend_iscsi_with_fallback = $cinder_backend_iscsi
    }

    if (str2bool_i("$cinder_backend_rbd") or ($glance_backend == 'rbd')) {
      include ::quickstack::ceph::client_packages
      # hack around the glance package declaration if needed
      if ($glance_backend != 'rbd') {
        package {'python-ceph': } -> Class['quickstack::ceph::client_packages']
      }
      if $ceph_fsid {
        class { '::quickstack::ceph::config':
          fsid                => $ceph_fsid,
          cluster_network     => $ceph_cluster_network,
          public_network      => $ceph_public_network,
          mon_initial_members => $ceph_mon_initial_members,
          mon_host            => $ceph_mon_host,
          images_key          => $ceph_images_key,
          volumes_key         => $ceph_volumes_key,
        } -> Class['quickstack::ceph::client_packages']
      }

      class {'quickstack::firewall::cinder':}
    }

    class { 'quickstack::cinder_volume':
      backend_eqlx           => $cinder_backend_eqlx,
      backend_eqlx_name      => $cinder_backend_eqlx_name,
      backend_glusterfs      => $cinder_backend_gluster,
      backend_glusterfs_name => $cinder_backend_gluster_name,
      backend_iscsi          => $cinder_backend_iscsi_with_fallback,
      backend_iscsi_name     => $cinder_backend_iscsi_name,
      backend_nfs            => $cinder_backend_nfs,
      backend_nfs_name       => $cinder_backend_nfs_name,
      backend_rbd            => $cinder_backend_rbd,
      backend_rbd_name       => $cinder_backend_rbd_name,
      multiple_backends      => $cinder_multiple_backends,
      # TODO: Create a parameter
      iscsi_bind_addr        => localhost,
      glusterfs_shares       => $cinder_gluster_shares,
      nfs_shares             => $cinder_nfs_shares,
      nfs_mount_options      => $cinder_nfs_mount_options,
      san_ip                 => $cinder_san_ip,
      san_login              => $cinder_san_login,
      san_password           => $cinder_san_password,
      san_thin_provision     => $cinder_san_thin_provision,
      eqlx_group_name        => $cinder_eqlx_group_name,
      eqlx_pool              => $cinder_eqlx_pool,
      eqlx_use_chap          => $cinder_eqlx_use_chap,
      eqlx_chap_login        => $cinder_eqlx_chap_login,
      eqlx_chap_password     => $cinder_eqlx_chap_password,
      rbd_pool               => $cinder_rbd_pool,
      rbd_ceph_conf          => $cinder_rbd_ceph_conf,
      rbd_flatten_volume_from_snapshot
                             => $cinder_rbd_flatten_volume_from_snapshot,
      rbd_max_clone_depth    => $cinder_rbd_max_clone_depth,
      rbd_user               => $cinder_rbd_user,
      rbd_secret_uuid        => $cinder_rbd_secret_uuid,
    }
  }

  if str2bool_i("$heat") {

    if str2bool_i("$ssl") {
      $sql_connection = "mysql://heat:${heat_db_password}@${mysql_host}/heat?ssl_ca=${mysql_ca}"
    } else {
      $sql_connection = "mysql://heat:${heat_db_password}@${mysql_host}/heat"
    }

    class { '::heat':
        keystone_host     => $controller_priv_host,
        keystone_password => $heat_user_password,
        auth_uri          => "http://${controller_priv_host}:35357/v2.0",
        rpc_backend       => amqp_backend('heat', $amqp_provider),
        qpid_hostname     => $amqp_host,
        qpid_port         => $amqp_port,
        qpid_protocol     => $qpid_protocol,
        qpid_username     => $amqp_username,
        qpid_password     => $amqp_password,
        rabbit_host       => $amqp_host,
        rabbit_port       => $amqp_port,
        rabbit_userid     => $amqp_username,
        rabbit_password   => $amqp_password,
        verbose           => $verbose,
        sql_connection    => $sql_connection,
    }

    class { '::heat::api_cfn':
        enabled => str2bool_i("$heat_cfn"),
    }

    class { '::heat::api_cloudwatch':
        enabled => str2bool_i("$heat_cloudwatch"),
    }

    class { '::heat::engine':
        auth_encryption_key           => $auth_encryption_key,
        heat_metadata_server_url      => "http://${controller_priv_host}:8000",
        heat_waitcondition_server_url => "http://${controller_priv_host}:8000/v1/waitcondition",
        heat_watch_server_url         => "http://${controller_priv_host}:8003",
    }

    # TODO: this ain't no place to be creating a db locally as happens below
    class { 'heat::db::mysql':
      password      => $heat_db_password,
      host          => $mysql_host,
      allowed_hosts => "%%",
    }

    class { '::heat::api':}

    class {'quickstack::firewall::heat':}
  }

  # Horizon

  if str2bool_i("$horizon") {
    package {'python-memcached':
      ensure => installed,
    }~>
    package {'python-netaddr':
      ensure => installed,
      notify => Class['::horizon'],
    }

    file {'/etc/httpd/conf.d/rootredirect.conf':
      ensure  => present,
      content => 'RedirectMatch ^/$ /dashboard/',
      notify  => File['/etc/httpd/conf.d/openstack-dashboard.conf'],
    }

    class {'::horizon':
      secret_key            => $horizon_secret_key,
      keystone_default_role => '_member_',
      keystone_host         => $keystone_private_vip,
      fqdn                  => ["$horizon_vip", "$::fqdn", "$::hostname", 'localhost', '*'],
      listen_ssl            => str2bool_i("$ssl"),
      horizon_cert          => $horizon_cert,
      horizon_key           => $horizon_key,
      horizon_ca            => $horizon_ca,
    }

    class {'memcached':}

    class {'quickstack::firewall::horizon':}

    if ($::selinux != "false"){
      selboolean { 'httpd_can_network_connect':
        value => on,
        persistent => true,
      }
    }
  }

  if str2bool_i("$keystonerc") {
    # This exists to cover havana release, where we only exposed the pub and priv
    # hosts, admin was not a param there.
    if $keystone_admin_vip == undef or $keystone_admin_vip == '' {
      $real_admin_host = $keystone_private_vip
    } else {
      $real_admin_host = $keystone_admin_vip
    }

    class { 'quickstack::admin_client':
      admin_password        => $admin_password,
      controller_admin_host => $real_admin_host,
    }
  }

  # ToDO
  firewall { '001 nova volume incoming':
    proto    => 'tcp',
    dport    => '3260',
    action   => 'accept',
  }

  # ToDO
  firewall { '001 EC2 API incoming':
    proto    => 'tcp',
    dport    => '8773',
    action   => 'accept',
  }

  ### Openstack Networking (neutron)

  class { '::neutron':
    allow_overlapping_ips => str2bool_i("$allow_overlapping_ips"),
    bind_host             => $neutron_private_vip,
    core_plugin           => $neutron_core_plugin,
    enabled               => str2bool_i("$neutron"),
    rpc_backend           => amqp_backend('neutron', $amqp_provider),
    qpid_hostname         => $amqp_vip,
    qpid_port             => $amqp_port,
    qpid_protocol         => $qpid_protocol,
    qpid_username         => $amqp_username,
    qpid_password         => $amqp_password,
    rabbit_host           => $amqp_vip,
    rabbit_port           => $amqp_port,
    rabbit_user           => $amqp_username,
    rabbit_password       => $amqp_password,
    rabbit_use_ssl        => str2bool_i("$ssl"),
    kombu_ssl_keyfile     => $amqp_key,
    kombu_ssl_certfile    => $amqp_cert,
    kombu_ssl_ca_certs    => $amqp_ca,
    verbose               => $verbose,
  }
  ->
  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_user_password,
    neutron_url            => "http://${neutron_public_vip}:9696",
    neutron_admin_auth_url => "http://${keystone_private_vip}:35357/v2.0",
  }
  ->
  class { '::neutron::server::notifications':
    notify_nova_on_port_status_changes => true,
    notify_nova_on_port_data_changes   => true,
    nova_url                           => "http://${nova_public_vip}:8774/v2",
    nova_admin_auth_url                => "http://${nova_private_vip}:35357/v2.0",
    nova_admin_username                => "nova",
    nova_admin_password                => "${nova_user_password}",
  }
  ->
  # FIXME: This really should be handled by the neutron-puppet module, which has
  # a review request open right now: https://review.openstack.org/#/c/50162/
  # If and when that is merged (or similar), the below can be removed.
  exec { 'neutron-db-manage upgrade':
    command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
    path        => '/usr/bin',
    user        => 'neutron',
    logoutput   => 'on_failure',
    before      => Service['neutron-server'],
    require     => [Neutron_config['database/connection'], Neutron_config['DEFAULT/core_plugin']],
  }
  File['/etc/neutron/plugin.ini'] -> Exec['neutron-db-manage upgrade']

#  neutron_config {
#    'database/connection':                  value => $neutron_sql_connection;
#    'keystone_authtoken/auth_host':         value => $keystone_private_vip;
#    'keystone_authtoken/admin_tenant_name': value => 'services';
#    'keystone_authtoken/admin_user':        value => 'neutron';
#    'keystone_authtoken/admin_password':    value => $neutron_user_password;
#  }

  class { '::neutron::server':
    auth_host            => $keystone_private_vip,
    auth_password        => $neutron_user_password,
    auth_tenant          => $neutron_auth_tenant,
    auth_user            => $neutron_auth_user,
    connection           => $neutron_sql_connection,
    database_max_retries => $database_max_retries,
    enabled              => str2bool_i("$neutron"),
    manage_service       => str2bool_i("$neutron_manage_service"),
  }

  if $neutron_core_plugin == 'neutron.plugins.ml2.plugin.Ml2Plugin' {
    neutron_config {
      'DEFAULT/service_plugins':
        value => join(['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',]),
    }
    ->
    class { '::neutron::plugins::ml2':
      type_drivers          => $ml2_type_drivers,
      tenant_network_types  => $ml2_tenant_network_types,
      mechanism_drivers     => $ml2_mechanism_drivers,
      flat_networks         => $ml2_flat_networks,
      network_vlan_ranges   => $ml2_network_vlan_ranges,
      tunnel_id_ranges      => $ml2_tunnel_id_ranges,
      vxlan_group           => $ml2_vxlan_group,
      vni_ranges            => $ml2_vni_ranges,
      enable_security_group => str2bool_i("$ml2_security_group"),
      firewall_driver       => $ml2_firewall_driver,
    }

    # If cisco nexus is part of ml2 mechanism drivers,
    # setup Mech Driver Cisco Neutron plugin class.
    if ('cisco_nexus' in $ml2_mechanism_drivers) {
      class { 'neutron::plugins::ml2::cisco::nexus':
        nexus_config        => $nexus_config,
      }
    }
  }

  if $neutron_core_plugin == 'neutron.plugins.cisco.network_plugin.PluginV2' {
    class { 'quickstack::neutron::plugins::cisco':
      neutron_db_password          => $neutron_db_password,
      neutron_user_password        => $neutron_user_password,
      ovs_vlan_ranges              => $ovs_vlan_ranges,
      cisco_vswitch_plugin         => $cisco_vswitch_plugin,
      nexus_config                 => $nexus_config,
      cisco_nexus_plugin           => $cisco_nexus_plugin,
      nexus_credentials            => $nexus_credentials,
      provider_vlan_auto_create    => $provider_vlan_auto_create,
      provider_vlan_auto_trunk     => $provider_vlan_auto_trunk,
      mysql_host                   => $mysql_vip,
      mysql_ca                     => $mysql_ca,
      tenant_network_type          => $cisco_tenant_network_type,
    }
  }

  #  class { '::neutron::plugins::ovs':
  #    sql_connection      => $neutron_sql_connection,
  #    tenant_network_type => $tenant_network_type,
  #    network_vlan_ranges => $ovs_vlan_ranges,
  #    tunnel_id_ranges    => $tunnel_id_ranges,
  #    vxlan_udp_port      => $ovs_vxlan_udp_port,
  #  }

  neutron_plugin_ovs { 'AGENT/l2_population': value => "$ovs_l2_population"; }

  $local_ip = find_ip("$ovs_tunnel_network","$ovs_tunnel_iface","")

  class { '::neutron::agents::ovs':
    bridge_mappings  => $ovs_bridge_mappings,
    bridge_uplinks   => $ovs_bridge_uplinks,
    enabled          => str2bool_i("$neutron"),
    enable_tunneling => str2bool_i("$ovs_enable_tunneling"),
    #local_ip         => $local_ip,
    local_ip         => 'eth0',
    manage_service   => str2bool_i("$neutron_manage_service"),
    tunnel_types     => $ovs_tunnel_types,
    vxlan_udp_port   => $ovs_vxlan_udp_port,
  }

  class { '::neutron::agents::dhcp':
    enabled        => str2bool_i("$neutron"),
    manage_service => str2bool_i("$neutron_manage_service"),
  }

  class { '::neutron::agents::l3':
    enabled                 => str2bool_i("$neutron"),
    external_network_bridge => $neutron_ext_network_bridge,
    manage_service          => str2bool_i("$neutron_manage_service"),
  }

  class { 'neutron::agents::metadata':
    auth_password  => $neutron_user_password,
    auth_url       => "http://${keystonre_private_vip}:35357/v2.0",
    enabled        => str2bool_i("$neutron"),
    manage_service => str2bool_i("$neutron_manage_service"),
    metadata_ip    => $neutron_public_vip,
    shared_secret  => $neutron_metadata_proxy_secret,
  }

  if str2bool_i("$neutron") {
    if str2bool_i("$neutron_agent_lbaas") {
      class { 'neutron::agents::lbaas': }
     }

    if str2bool_i("$neutron_agent_fwaas") {
      class { 'neutron::agents::fwaas': }
    }
  }

  class {'quickstack::neutron::firewall::gre': }

  class {'quickstack::neutron::firewall::vxlan':
    port => $ovs_vxlan_udp_port,
  }

  class {'::quickstack::firewall::neutron':}

  ### Compute

  if str2bool_i("$cinder_backend_gluster") {
    if defined('gluster::client') {
      class { 'gluster::client': }
    } else {
      include ::puppet::vardir
      class { 'gluster::mount::base': repo => false }
    }

    if ($::selinux != "false") {
      selboolean{'virt_use_fusefs':
          value => on,
          persistent => true,
      }
    }

    nova_config {
      'DEFAULT/qemu_allowed_storage_drivers': value => 'gluster';
    }
  }

  if str2bool_i("$cinder_backend_nfs") {
    package { 'nfs-utils':
      ensure => 'present',
    }

    if ($::selinux != "false") {
      selboolean{'virt_use_nfs':
          value => on,
          persistent => true,
      }
    }
  }

  if (str2bool_i("$cinder_backend_rbd") or str2bool_i("$glance_backend_rbd")) {
    include ::quickstack::ceph::client_packages
    if $ceph_fsid {
      class { '::quickstack::ceph::config':
        fsid                => $ceph_fsid,
        cluster_network     => $ceph_cluster_network,
        public_network      => $ceph_public_network,
        mon_initial_members => $ceph_mon_initial_members,
        mon_host            => $ceph_mon_host,
        images_key          => $ceph_images_key,
        volumes_key         => $ceph_volumes_key,
      } -> Class['quickstack::ceph::client_packages']
    }
    package {'python-ceph': } ->
    Class['quickstack::ceph::client_packages'] -> Package['nova-compute']
  }

  if str2bool_i("$cinder_backend_rbd") {
    nova_config {
      'DEFAULT/libvirt_images_rbd_pool':      value => $libvirt_images_rbd_pool;
      'DEFAULT/libvirt_images_rbd_ceph_conf': value => $libvirt_images_rbd_ceph_conf;
      'DEFAULT/libvirt_inject_password':      value => $libvirt_inject_password;
      'DEFAULT/libvirt_inject_key':           value => $libvirt_inject_key;
      'DEFAULT/libvirt_inject_partition':     value => '-2';
      'DEFAULT/libvirt_images_type':          value => $libvirt_images_type;
      'DEFAULT/rbd_user':                     value => $cinder_rbd_user;
      'DEFAULT/rbd_secret_uuid':              value => $rbd_secret_uuid;
    }

    # the rest of this if block is borrowed from ::nova::compute::rbd
    # which we can't use due to a duplicate package declaration
    file { '/etc/nova/secret.xml':
      content => template('quickstack/compute-volumes-rbd-secret-xml.erb')
    }
    ->
    Class['quickstack::ceph::client_packages']
    ->
    Service[libvirt]
    ->
    exec { 'define-virsh-rbd-secret':
      command => '/usr/bin/virsh secret-define --file /etc/nova/secret.xml',
      onlyif => "/usr/bin/ceph --connect-timeout 10 auth get-key client.${libvirt_images_rbd_pool} >/dev/null 2>&1",
      creates => '/etc/nova/virsh.secret',
    }
    ->
    exec { 'set-virsh-rbd-secret-key':
      command => "/usr/bin/virsh secret-set-value --secret ${rbd_secret_uuid} --base64 \$(/usr/bin/ceph auth get-key client.${libvirt_images_rbd_pool})",
      onlyif => "/usr/bin/ceph --connect-timeout 10 auth get-key client.${libvirt_images_rbd_pool} >/dev/null 2>&1",
    }
  } else {
    nova_config {
      'DEFAULT/libvirt_inject_partition':     value => '-1';
    }
  }

  if str2bool_i($libvirt_kvm_capable) {
    $libvirt_type = 'kvm'
  } else {
    include quickstack::compute::qemu
    $libvirt_type = 'qemu'
  }

  class { '::nova::compute::libvirt':
    libvirt_type => $libvirt_type,
    vncserver_listen => '0.0.0.0',
  }

  $compute_ip = find_ip("$private_network",
                        "$private_iface",
                        "$private_ip")

  class { '::nova::compute':
    enabled => true,
    vncproxy_host => $nova_private_vip,
    vncserver_proxyclient_address => $compute_ip,
  }

  include quickstack::tuned::virtual_host

  # TODO
  firewall { '001 nova compute incoming':
    proto  => 'tcp',
    dport  => '5900-5999',
    action => 'accept',
  }
}
