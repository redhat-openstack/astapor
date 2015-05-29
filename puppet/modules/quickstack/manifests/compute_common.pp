# == Class: quickstack::compute_common
#
# A base class to configure compute nodes
#
# === Parameters
# [*nova_host*]
#   The private network ip for the controller, or nova VIP, if HA.
# [*vncproxy_host*]
#   The ip or hostname to use for constructing the VNC console base URL.
#   Typically the public network ip or hostname for the controller, or nova VIP, if HA.
#   Defaults to the value of nova_host if unset.

class quickstack::compute_common (
  $amqp_host                    = $quickstack::params::amqp_host,
  $amqp_password                = $quickstack::params::amqp_password,
  $amqp_port                    = '5672',
  $amqp_provider                = $quickstack::params::amqp_provider,
  $amqp_username                = $quickstack::params::amqp_username,
  $amqp_ssl_port                = '5671',
  $auth_host                    = '127.0.0.1',
  $ceilometer                   = 'true',
  $ceilometer_metering_secret   = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password     = $quickstack::params::ceilometer_user_password,
  $manage_ceph_conf             = true,
  $ceph_cluster_network         = '',
  $ceph_public_network          = '',
  $ceph_fsid                    = '',
  $ceph_images_key              = '',
  $ceph_volumes_key             = '',
  $ceph_rgw_key                 = '',
  $ceph_mon_host                = [ ],
  $ceph_mon_initial_members     = [ ],
  $ceph_conf_include_osd_global = true,
  $ceph_osd_pool_size           = '',
  $ceph_osd_journal_size        = '',
  $ceph_osd_mkfs_options_xfs    = '-f -i size=2048 -n size=64k',
  $ceph_osd_mount_options_xfs   = 'inode64,noatime,logbsize=256k',
  $ceph_conf_include_rgw        = false,
  $ceph_rgw_hostnames           = [ ],
  $ceph_extra_conf_lines        = [ ],
  $cinder_backend_gluster       = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_nfs           = 'false',
  $cinder_backend_rbd           = 'false',
  $cinder_catalog_info          = 'volume:cinder:internalURL',
  $glance_host                  = '127.0.0.1',
  $glance_backend_rbd           = 'false',
  $libvirt_images_rbd_pool      = 'volumes',
  $libvirt_images_rbd_ceph_conf = '/etc/ceph/ceph.conf',
  $libvirt_inject_password      = 'false',
  $libvirt_inject_key           = 'false',
  $libvirt_images_type          = 'rbd',
  $mysql_ca                     = $quickstack::params::mysql_ca,
  $mysql_host                   = $quickstack::params::mysql_host,
  $nova_host                    = '127.0.0.1',
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $private_network              = '',
  $private_iface                = '',
  $private_ip                   = '',
  $rabbit_hosts                 = undef,
  $rbd_user                     = 'volumes',
  $rbd_secret_uuid              = '',
  $network_device_mtu           = $quickstack::params::network_device_mtu,
  $ssl                          = $quickstack::params::ssl,
  $verbose                      = $quickstack::params::verbose,
  $vnc_keymap                   = 'en-us',
  $vncproxy_host                = undef,
) inherits quickstack::params {

  class {'quickstack::openstack_common': }

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
        manage_ceph_conf        => $manage_ceph_conf,
        fsid                    => $ceph_fsid,
        cluster_network         => $ceph_cluster_network,
        public_network          => $ceph_public_network,
        mon_initial_members     => $ceph_mon_initial_members,
        mon_host                => $ceph_mon_host,
        images_key              => $ceph_images_key,
        volumes_key             => $ceph_volumes_key,
        rgw_key                 => $ceph_rgw_key,
        conf_include_osd_global => $ceph_conf_include_osd_global,
        osd_pool_default_size   => $ceph_osd_pool_size,
        osd_journal_size        => $ceph_osd_journal_size,
        osd_mkfs_options_xfs    => $ceph_osd_mkfs_options_xfs,
        osd_mount_options_xfs   => $ceph_osd_mount_options_xfs,
        conf_include_rgw        => $ceph_conf_include_rgw,
        rgw_hostnames           => $ceph_rgw_hostnames,
        extra_conf_lines        => $ceph_extra_conf_lines,
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
      'DEFAULT/rbd_user':                     value => $rbd_user;
      'DEFAULT/rbd_secret_uuid':              value => $rbd_secret_uuid;
    }

    Package['nova-common'] ->
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
      creates => '/etc/nova/virsh.secret',
    }
    ->
    exec { 'set-virsh-rbd-secret-key':
      command => "/usr/bin/virsh secret-set-value --secret ${rbd_secret_uuid} --base64 ${ceph_volumes_key}",
    }
  } else {
    nova_config {
      'DEFAULT/libvirt_inject_partition':     value => '-1';
    }
  }

  nova_config {
    'DEFAULT/cinder_catalog_info': value => $cinder_catalog_info;
  }

  if str2bool_i("$ssl") {
    $qpid_protocol = 'ssl'
    $real_amqp_port = $amqp_ssl_port
    $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_host}/nova?ssl_ca=${mysql_ca}"

  } else {
    $qpid_protocol = 'tcp'
    $real_amqp_port = $amqp_port
    $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_host}/nova"
  }

  if $rabbit_hosts {
    nova_config { 'DEFAULT/rabbit_host': ensure => absent }
    nova_config { 'DEFAULT/rabbit_port': ensure => absent }
  }

  class { '::nova':
    database_connection => $nova_sql_connection,
    image_service       => 'nova.image.glance.GlanceImageService',
    glance_api_servers  => "http://${glance_host}:9292/v1",
    rpc_backend         => amqp_backend('nova', $amqp_provider),
    qpid_hostname       => $amqp_host,
    qpid_protocol       => $qpid_protocol,
    qpid_port           => $real_amqp_port,
    qpid_username       => $amqp_username,
    qpid_password       => $amqp_password,
    rabbit_host         => $amqp_host,
    rabbit_port         => $real_amqp_port,
    rabbit_userid       => $amqp_username,
    rabbit_password     => $amqp_password,
    rabbit_use_ssl      => $ssl,
    rabbit_hosts        => $rabbit_hosts,
    verbose             => $verbose,
  }

  if str2bool_i($kvm_capable) {
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
    enabled                       => true,
    vncproxy_host                 => pick($vncproxy_host, $nova_host),
    vncserver_proxyclient_address => $compute_ip,
    network_device_mtu            => $network_device_mtu,
    vnc_keymap                    => $vnc_keymap,
  }

  if str2bool_i("$ceilometer") {
    class { 'ceilometer':
      metering_secret => $ceilometer_metering_secret,
      qpid_protocol   => $qpid_protocol,
      qpid_username   => $amqp_username,
      qpid_password   => $amqp_password,
      rabbit_host     => $amqp_host,
      rabbit_hosts    => $rabbit_hosts,
      rabbit_port     => $real_amqp_port,
      rabbit_userid   => $amqp_username,
      rabbit_password => $amqp_password,
      rabbit_use_ssl  => $ssl,
      rpc_backend     => amqp_backend('ceilometer', $amqp_provider),
      verbose         => $verbose,
    }

    class { 'ceilometer::agent::auth':
      auth_url      => "http://${auth_host}:35357/v2.0",
      auth_password => $ceilometer_user_password,
    }

    class { 'ceilometer::agent::compute':
      enabled => true,
    }
    Package['openstack-nova-common'] -> Package['ceilometer-common']
  }

  include quickstack::tuned::virtual_host

  firewall { '001 nova compute incoming':
    proto  => 'tcp',
    dport  => '5900-5999',
    action => 'accept',
  }
}
