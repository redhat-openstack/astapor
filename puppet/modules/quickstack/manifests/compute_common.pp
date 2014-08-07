# Quickstack compute node
class quickstack::compute_common (
  $admin_password               = $quickstack::params::admin_password,
  $ceilometer                   = 'true',
  $auth_host                    = '127.0.0.1',
  $ceilometer_metering_secret   = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password     = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster       = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_nfs           = 'false',
  $cinder_backend_rbd           = 'false',
  $glance_host                  = '127.0.0.1',
  $mysql_host                   = $quickstack::params::mysql_host,
  $nova_host                    = '127.0.0.1',
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $amqp_provider                = $quickstack::params::amqp_provider,
  $amqp_host                    = $quickstack::params::amqp_host,
  $amqp_port                    = '5672',
  $amqp_ssl_port                = '5671',
  $amqp_username                = $quickstack::params::amqp_username,
  $amqp_password                = $quickstack::params::amqp_password,
  $verbose                      = $quickstack::params::verbose,
  $ssl                          = $quickstack::params::ssl,
  $mysql_ca                     = $quickstack::params::mysql_ca,
  $libvirt_images_rbd_pool      = 'volumes',
  $libvirt_images_rbd_ceph_conf = '/etc/ceph/ceph.conf',
  $libvirt_inject_password      = 'false',
  $libvirt_inject_key           = 'false',
  $libvirt_images_type          = 'rbd',
  $rbd_user                     = 'volumes',
  $rbd_secret_uuid              = '',
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

  if str2bool_i("$cinder_backend_rbd") {
    include ::quickstack::ceph::client_packages
    package {'python-ceph': }

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
  } else {
    nova_config {
      'DEFAULT/libvirt_inject_partition':     value => '-1';
    }
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

  class { '::nova':
    sql_connection     => $nova_sql_connection,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "http://${glance_host}:9292/v1",
    rpc_backend        => amqp_backend('nova', $amqp_provider),
    qpid_hostname      => $amqp_host,
    qpid_protocol      => $qpid_protocol,
    qpid_port          => $real_amqp_port,
    qpid_username      => $amqp_username,
    qpid_password      => $amqp_password,
    rabbit_host        => $amqp_host,
    rabbit_port        => $real_amqp_port,
    rabbit_userid      => $amqp_username,
    rabbit_password    => $amqp_password,
    verbose            => $verbose,
  }

  if str2bool_i($kvm_capable) {
    $libvirt_type = 'kvm'
  } else {
    include quickstack::compute::qemu
    $libvirt_type = 'qemu'
  }

  class { '::nova::compute::libvirt':
    libvirt_type => $libvirt_type,
    vncserver_listen => $::ipaddress,
  }

  class { '::nova::compute':
    enabled => true,
    vncproxy_host => $nova_host,
    vncserver_proxyclient_address => $::ipaddress,
  }

  if str2bool_i("$ceilometer") {
    class { 'ceilometer':
      metering_secret => $ceilometer_metering_secret,
      qpid_protocol   => $qpid_protocol,
      qpid_username   => $amqp_username,
      qpid_password   => $amqp_password,
      rabbit_host     => $amqp_host,
      rabbit_port     => $real_amqp_port,
      rabbit_userid   => $amqp_username,
      rabbit_password => $amqp_password,
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
