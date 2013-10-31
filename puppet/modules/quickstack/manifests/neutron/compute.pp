# Common quickstack configurations
class quickstack::neutron::compute (
  $metadata_proxy_shared_secret = $quickstack::params::metadata_proxy_shared_secret,
  $admin_password              = $quickstack::params::admin_password,
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $fixed_network_range         = $quickstack::params::fixed_network_range,
  $floating_network_range      = $quickstack::params::floating_network_range,
  $neutron_db_password         = $quickstack::params::neutron_db_password,
  $neutron_user_password       = $quickstack::params::neutron_user_password,
  $neutron_core_plugin         = $quickstack::params::neutron_core_plugin,
  $tenant_network_type         = $quickstack::params::tenant_network_type,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip  = $quickstack::params::controller_pub_floating_ip,
  $private_interface           = $quickstack::params::private_interface,
  $public_interface            = $quickstack::params::public_interface,
  $ovs_bridge_mappings         = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks          = $quickstack::params::ovs_bridge_uplinks,
  $mysql_host                  = $quickstack::params::mysql_host,
  $qpid_host                   = $quickstack::params::qpid_host,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {

  if $glance_backend_gluster == true {
    class { 'gluster::client': }
  }

  # Configure Nova
  nova_config{
      'DEFAULT/libvirt_inject_partition':             value => '-1';
      'keystone_authtoken/admin_tenant_name':         value => 'admin';
      'keystone_authtoken/admin_user':                value => 'admin';
      'keystone_authtoken/admin_password':            value => $admin_password;
      'keystone_authtoken/auth_host':                 value => $controller_priv_floating_ip;
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
  #    ensure => link,
  #    target => "/usr/libexec/qemu-kvm",
  #    notify => Service["nova-compute"],
  #}
  #nova_config{
  #    "libvirt_cpu_mode": value => "none";
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
      enabled                              => true,
      admin_password                       => $nova_user_password,
      auth_host                            => $controller_priv_floating_ip,
      neutron_metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
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

  class { '::neutron':
      allow_overlapping_ips => true,
      rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
      qpid_hostname         => $qpid_host,
      core_plugin           => $neutron_core_plugin
  }

  neutron_config {
      'database/connection': value => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron";
      'keystone_authtoken/auth_host':         value => $controller_priv_floating_ip;
      'keystone_authtoken/admin_tenant_name': value => 'admin';
      'keystone_authtoken/admin_user':        value => 'admin';
      'keystone_authtoken/admin_password':    value => $admin_password;
  }

  class { '::neutron::plugins::ovs':
      sql_connection      => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron",
      tenant_network_type => $tenant_network_type,
  }

  class { '::neutron::agents::ovs':
      bridge_uplinks   => $ovs_bridge_uplinks,
      bridge_mappings  => $ovs_bridge_mappings,
      local_ip         => getvar("ipaddress_${private_interface}"),
      enable_tunneling => true,
  }

  class { '::nova::network::neutron':
      neutron_admin_password    => $neutron_user_password,
      neutron_url               => "http://${controller_priv_floating_ip}:9696",
      neutron_admin_auth_url    => "http://${controller_priv_floating_ip}:35357/v2.0",
  }

  firewall { '001 nova compute incoming':
      proto  => 'tcp',
      dport  => '5900-5999',
      action => 'accept',
  }
}
