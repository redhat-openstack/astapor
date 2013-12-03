# Quickstack compute node configuration for neutron (OpenStack Networking)
class quickstack::neutron::compute (
  $admin_password              = $quickstack::params::admin_password,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip  = $quickstack::params::controller_pub_floating_ip,
  $mysql_host                  = $quickstack::params::mysql_host,
  $neutron_core_plugin         = $quickstack::params::neutron_core_plugin,
  $neutron_db_password         = $quickstack::params::neutron_db_password,
  $neutron_user_password       = $quickstack::params::neutron_user_password,
  $ovs_bridge_mappings         = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks          = $quickstack::params::ovs_bridge_uplinks,
  $private_interface           = $quickstack::params::private_interface,
  $public_interface            = $quickstack::params::public_interface,
  $qpid_host                   = $quickstack::params::qpid_host,
  $tenant_network_type         = $quickstack::params::tenant_network_type,
) inherits quickstack::params {

  class { '::neutron':
    allow_overlapping_ips => true,
    rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
    qpid_hostname         => $qpid_host,
    core_plugin           => $neutron_core_plugin
  }

  neutron_config {
    'database/connection': value => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron";
    'keystone_authtoken/auth_host':         value => $controller_priv_floating_ip;
    'keystone_authtoken/admin_tenant_name': value => 'services';
    'keystone_authtoken/admin_user':        value => 'neutron';
    'keystone_authtoken/admin_password':    value => $neutron_user_password;
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
}
