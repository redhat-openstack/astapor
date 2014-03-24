# Quickstack compute node
class quickstack::compute_common (
  $admin_password              = $quickstack::params::admin_password,
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $nova_libgfapi			   = $quickstack::params::nova_libgfapi,
  $controller_priv_host        = $quickstack::params::controller_priv_host,
  $controller_pub_host         = $quickstack::params::controller_pub_host,
  $mysql_host                  = $quickstack::params::mysql_host,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $qpid_host                   = $quickstack::params::qpid_host,
  $verbose                     = $quickstack::params::verbose,
  $ssl                         = $quickstack::params::ssl,
  $mysql_ca                    = $quickstack::params::mysql_ca,
) inherits quickstack::params {

  if str2bool_i("$cinder_backend_gluster") {
    class { 'gluster::client': }

  if str2bool_i("$nova_libgfapi") {
	   nova_config{
	   	"DEFAULT/qemu_allowed_storage_drivers": value => "gluster";
	   }
  }

    if ($::selinux != "false") {
      selboolean{'virt_use_fusefs':
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
      $qpid_port = '5671'
      $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_host}/nova?ssl_ca=${mysql_ca}"

    } else {
      $qpid_protocol = 'tcp'
      $qpid_port = '5672'
      $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_host}/nova"
    }

  class { 'nova':
    sql_connection     => $nova_sql_connection,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "http://${controller_priv_host}:9292/v1",
    rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
    qpid_hostname      => $qpid_host,
    qpid_protocol      => $qpid_protocol,
    qpid_port          => $qpid_port,
    verbose            => $verbose,
  }

  # uncomment if on a vm
  # GSutclif: Maybe wrap this in a Facter['is-virtual'] test ?
  #file { "/usr/bin/qemu-system-x86_64":
  #  ensure => link,
  #  target => "/usr/libexec/qemu-kvm",
  #  notify => Service["nova-compute"],
  #}
  #nova_config{
  #  "libvirt_cpu_mode": value => "none";
  #}

  class { 'nova::compute::libvirt':
    #libvirt_type    => "qemu",  # uncomment if on a vm
    vncserver_listen => $::ipaddress,
  }

  class { 'nova::compute':
    enabled => true,
    vncproxy_host => $controller_pub_host,
    vncserver_proxyclient_address => $::ipaddress,
  }

  class { 'ceilometer':
    metering_secret => $ceilometer_metering_secret,
    qpid_hostname   => $qpid_host,
    qpid_port       => $qpid_port,
    qpid_protocol   => $qpid_protocol,
    rpc_backend     => 'ceilometer.openstack.common.rpc.impl_qpid',
    verbose         => $verbose,
  }

  class { 'ceilometer::agent::auth':
    auth_url      => "http://${controller_priv_host}:35357/v2.0",
    auth_password => $ceilometer_user_password,
  }

  class { 'ceilometer::agent::compute':
    enabled => true,
  }

  include quickstack::tuned::virtual_host

  firewall { '001 nova compute incoming':
    proto  => 'tcp',
    dport  => '5900-5999',
    action => 'accept',
  }
}
