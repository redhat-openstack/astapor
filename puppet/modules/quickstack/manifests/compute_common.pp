# Quickstack compute node
class quickstack::compute_common (
  $admin_password              = $quickstack::params::admin_password,
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip  = $quickstack::params::controller_pub_floating_ip,
  $mysql_host                  = $quickstack::params::mysql_host,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $qpid_host                   = $quickstack::params::qpid_host,
  $qpid_username               = $quickstack::params::qpid_username,
  $qpid_password               = $quickstack::params::qpid_password,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {

  if str2bool($cinder_backend_gluster) == true {
    class { 'gluster::client': }
  }

  nova_config {
    'DEFAULT/libvirt_inject_partition':     value => '-1';
  }

  class { 'nova':
    sql_connection     => "mysql://nova:${nova_db_password}@${mysql_host}/nova",
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "http://${controller_priv_floating_ip}:9292/v1",
    rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
    qpid_hostname      => $qpid_host,
    qpid_username      => $qpid_username,
    qpid_password      => $qpid_password,
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
    vncproxy_host => $controller_pub_floating_ip,
    vncserver_proxyclient_address => $::ipaddress,
  }

  class { 'ceilometer':
    metering_secret => $ceilometer_metering_secret,
    qpid_hostname   => $qpid_host,
    qpid_username   => $qpid_username,
    qpid_password   => $qpid_password,
    rpc_backend     => 'ceilometer.openstack.common.rpc.impl_qpid',
    verbose         => $verbose,
  }

  class { 'ceilometer::agent::auth':
    auth_url      => "http://${controller_priv_floating_ip}:35357/v2.0",
    auth_password => $ceilometer_user_password,
  }

  class { 'ceilometer::agent::compute':
    enabled => true,
  }

  firewall { '001 nova compute incoming':
    proto  => 'tcp',
    dport  => '5900-5999',
    action => 'accept',
  }
}
