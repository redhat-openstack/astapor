# Quickstack compute node
class quickstack::compute (
  $admin_password              = $quickstack::params::admin_password,
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip  = $quickstack::params::controller_pub_floating_ip,
  $fixed_network_range         = $quickstack::params::fixed_network_range,
  $floating_network_range      = $quickstack::params::floating_network_range,
  $mysql_host                  = $quickstack::params::mysql_host,
  $neutron                     = $quickstack::params::neutron,
  $neutron_core_plugin         = $quickstack::params::neutron_core_plugin,
  $neutron_db_password         = $quickstack::params::neutron_db_password,
  $neutron_user_password       = $quickstack::params::neutron_user_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $ovs_bridge_mappings         = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks          = $quickstack::params::ovs_bridge_uplinks,
  $private_interface           = $quickstack::params::private_interface,
  $public_interface            = $quickstack::params::public_interface,
  $qpid_host                   = $quickstack::params::qpid_host,
  $tenant_network_type         = $quickstack::params::tenant_network_type,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {

  if str2bool($cinder_backend_gluster) == true {
    class { 'gluster::client': }
  }

  nova_config {
    'DEFAULT/libvirt_inject_partition':     value => '-1';
    'keystone_authtoken/admin_tenant_name': value => 'admin';
    'keystone_authtoken/admin_user':        value => 'admin';
    'keystone_authtoken/admin_password':    value => $admin_password;
    'keystone_authtoken/auth_host':         value => $controller_priv_floating_ip;
  }

  class { 'nova':
    sql_connection     => "mysql://nova:${nova_db_password}@${mysql_host}/nova",
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "http://${controller_priv_floating_ip}:9292/v1",
    rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
    qpid_hostname      => $qpid_host,
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

  class { 'nova::api':
    enabled           => true,
    admin_password    => $nova_user_password,
    auth_host         => $controller_priv_floating_ip,
  }

  class { 'ceilometer':
    metering_secret => $ceilometer_metering_secret,
    qpid_hostname   => $qpid_host,
    rpc_backend     => 'ceilometer.openstack.common.rpc.impl_qpid',
    verbose         => $verbose,
  }

  class { 'ceilometer::agent::compute':
    auth_url      => "http://${controller_priv_floating_ip}:35357/v2.0",
    auth_password => $ceilometer_user_password,
  }

  if str2bool("$neutron") {
    class { '::quickstack::neutron::compute':
      controller_priv_floating_ip => $controller_priv_floating_ip,
      controller_pub_floating_ip  => $controller_pub_floating_ip,
      mysql_host                  => $mysql_host,
      neutron_core_plugin         => $neutron_core_plugin,
      neutron_db_password         => $neutron_db_password,
      neutron_user_password       => $neutron_user_password,
      ovs_bridge_mappings         => $ovs_bridge_mappings,
      ovs_bridge_uplinks          => $ovs_bridge_uplinks,
      private_interface           => $private_interface,
      public_interface            => $public_interface,
      qpid_host                   => $qpid_host,
      tenant_network_type         => $tenant_network_type,
    }
  }
  else {
    class { '::quickstack::nova_network::compute':
      controller_priv_floating_ip => $controller_priv_floating_ip,
      controller_pub_floating_ip  => $controller_pub_floating_ip,
      fixed_network_range         => $fixed_network_range,
      floating_network_range      => $floating_network_range,
      private_interface           => $private_interface,
      public_interface            => $public_interface,
    }
  }

  firewall { '001 nova compute incoming':
    proto  => 'tcp',
    dport  => '5900-5999',
    action => 'accept',
  }
}
