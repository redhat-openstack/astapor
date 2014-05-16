# Quickstack compute node
class quickstack::compute_common (
  $admin_password              = $quickstack::params::admin_password,
  $ceilometer                  = 'true',
  $auth_host                   = '127.0.0.1',
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_nfs          = 'false',
  $glance_host                 = '127.0.0.1',
  $mysql_host                  = $quickstack::params::mysql_host,
  $nova_host                   = '127.0.0.1',
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $qpid_host                   = $quickstack::params::qpid_host,
  $qpid_port                   = '5672',
  $qpid_ssl_port               = '5671',
  $qpid_username               = $quickstack::params::qpid_username,
  $qpid_password               = $quickstack::params::qpid_password,
  $verbose                     = $quickstack::params::verbose,
  $ssl                         = $quickstack::params::ssl,
  $mysql_ca                    = $quickstack::params::mysql_ca,
  $use_qemu_for_poc            = $quickstack::params::use_qemu_for_poc,
) inherits quickstack::params {

  class {'quickstack::openstack_common': }

  if str2bool_i("$cinder_backend_gluster") {
    if defined('gluster::client') {
      class { 'gluster::client': }
    } else {
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
    if ($::selinux != "false") {
      selboolean{'virt_use_nfs':
          value => on,
          persistent => true,
      }
    }
  }

  nova_config {
    'DEFAULT/libvirt_inject_partition':     value => '-1';
  }

    if str2bool_i("$ssl") {
      $qpid_protocol = 'ssl'
      $real_qpid_port = $qpid_ssl_port
      $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_host}/nova?ssl_ca=${mysql_ca}"

    } else {
      $qpid_protocol = 'tcp'
      $real_qpid_port = $qpid_port
      $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_host}/nova"
    }

  class { '::nova':
    sql_connection     => $nova_sql_connection,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "http://${glance_host}:9292/v1",
    rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
    qpid_hostname      => $qpid_host,
    qpid_protocol      => $qpid_protocol,
    qpid_port          => $real_qpid_port,
    qpid_username      => $qpid_username,
    qpid_password      => $qpid_password,
    verbose            => $verbose,
  }

  if str2bool_i("$use_qemu_for_poc") {
    $libvirt_type = 'qemu'
  } else {
    $libvirt_type = 'kvm'
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
      qpid_hostname   => $qpid_host,
      qpid_port       => $real_qpid_port,
      qpid_protocol   => $qpid_protocol,
      qpid_username   => $qpid_username,
      qpid_password   => $qpid_password,
      rpc_backend     => 'ceilometer.openstack.common.rpc.impl_qpid',
      verbose         => $verbose,
    }

    class { 'ceilometer::agent::auth':
      auth_url      => "http://${auth_host}:35357/v2.0",
      auth_password => $ceilometer_user_password,
    }

    class { 'ceilometer::agent::compute':
      enabled => true,
    }
  }

  if str2bool_i("$use_qemu_for_poc")  {
    include quickstack::compute::qemu
  }

  include quickstack::tuned::virtual_host

  firewall { '001 nova compute incoming':
    proto  => 'tcp',
    dport  => '5900-5999',
    action => 'accept',
  }
}
