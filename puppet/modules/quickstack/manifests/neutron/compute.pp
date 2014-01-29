# Quickstack compute node configuration for neutron (OpenStack Networking)
class quickstack::neutron::compute (
  $admin_password              = $quickstack::params::admin_password,
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $controller_admin_host       = $quickstack::params::controller_admin_host,
  $controller_priv_host        = $quickstack::params::controller_priv_host,
  $controller_pub_host         = $quickstack::params::controller_pub_host,
  $enable_tunneling            = $quickstack::params::enable_tunneling,
  $mysql_host                  = $quickstack::params::mysql_host,
  $neutron_core_plugin         = $quickstack::params::neutron_core_plugin,
  $neutron_db_password         = $quickstack::params::neutron_db_password,
  $neutron_user_password       = $quickstack::params::neutron_user_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $ovs_bridge_mappings         = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks          = $quickstack::params::ovs_bridge_uplinks,
  $ovs_vlan_ranges             = $quickstack::params::ovs_vlan_ranges,
  $ovs_tunnel_iface            = 'em1',
  $qpid_host                   = $quickstack::params::qpid_host,
  $tenant_network_type         = $quickstack::params::tenant_network_type,
  $tunnel_id_ranges            = '1:1000',
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {

  # str2bool expects the string to already be downcased.  all-righty.
  # (i.e. str2bool('True') would blow up, so work around it.)
  $enable_tunneling_bool = $enable_tunneling ? {
      /(?i:true)/   => true,
      /(?i:false)/  => false,
      default => str2bool("$enable_tunneling"),
  }

  class { '::neutron':
    allow_overlapping_ips => true,
    rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
    qpid_hostname         => $qpid_host,
    core_plugin           => $neutron_core_plugin
  }

  neutron_config {
    'database/connection': value => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron";
    'keystone_authtoken/auth_host':         value => $controller_priv_host;
    'keystone_authtoken/admin_tenant_name': value => 'services';
    'keystone_authtoken/admin_user':        value => 'neutron';
    'keystone_authtoken/admin_password':    value => $neutron_user_password;
  }

  class { '::neutron::plugins::ovs':
    sql_connection      => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron",
    tenant_network_type => $tenant_network_type,
    network_vlan_ranges => $ovs_vlan_ranges,
    tunnel_id_ranges    => $tunnel_id_ranges,
  }

  class { '::neutron::agents::ovs':
    bridge_uplinks      => $ovs_bridge_uplinks,
    bridge_mappings     => $ovs_bridge_mappings,
    local_ip            => getvar(regsubst("ipaddress_${ovs_tunnel_iface}", '\.', '_', 'G')),
    enable_tunneling    => $enable_tunneling_bool,
  }

  class { '::nova::network::neutron':
    neutron_admin_password    => $neutron_user_password,
    neutron_url               => "http://${controller_priv_host}:9696",
    neutron_admin_auth_url    => "http://${controller_admin_host}:35357/v2.0",
  }


  class { 'quickstack::compute_common':
    admin_password              => $admin_password,
    ceilometer_metering_secret  => $ceilometer_metering_secret,
    ceilometer_user_password    => $ceilometer_user_password,
    cinder_backend_gluster      => $cinder_backend_gluster,
    controller_priv_host        => $controller_priv_host,
    controller_pub_host         => $controller_pub_host,
    mysql_host                  => $mysql_host,
    nova_db_password            => $nova_db_password,
    nova_user_password          => $nova_user_password,
    qpid_host                   => $qpid_host,
    verbose                     => $verbose,
  }
}
