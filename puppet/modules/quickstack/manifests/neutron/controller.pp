# Quickstart controller class for nova neutron (OpenStack Networking)
class quickstack::neutron::controller (
  $admin_email                  = $quickstack::params::admin_email,
  $admin_password               = $quickstack::params::admin_password,
  $bridge_interface             = $quickstack::params::bridge_interface,
  $cisco_nexus_plugin           = $quickstack::params::cisco_nexus_plugin,
  $cisco_vswitch_plugin         = $quickstack::params::cisco_vswitch_plugin,
  $controller_priv_floating_ip  = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip   = $quickstack::params::controller_pub_floating_ip,
  $mysql_host                   = $quickstack::params::mysql_host,
  $neutron_core_plugin          = $quickstack::params::neutron_core_plugin,
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $neutron_user_password        = $quickstack::params::neutron_user_password,
  $nexus_config                 = $quickstack::params::nexus_config,
  $nexus_credentials            = $quickstack::params::nexus_credentials,
  $ovs_vlan_ranges              = $quickstack::params::ovs_vlan_ranges,
  $provider_vlan_auto_create    = $quickstack::params::provider_vlan_auto_create,
  $provider_vlan_auto_trunk     = $quickstack::params::provider_vlan_auto_trunk,
  $qpid_host                    = $quickstack::params::qpid_host,
  $tenant_network_type          = $quickstack::params::tenant_network_type,
  $verbose                      = $quickstack::params::verbose,
) inherits quickstack::params {

  nova_config {
    'keystone_authtoken/admin_tenant_name': value => 'admin';
    'keystone_authtoken/admin_user':        value => 'admin';
    'keystone_authtoken/admin_password':    value => $admin_password;
    'keystone_authtoken/auth_host':         value => '127.0.0.1';
  }

  class { '::neutron':
    enabled               => true,
    verbose               => $verbose,
    allow_overlapping_ips => true,
    rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
    qpid_hostname         => $qpid_host,
    core_plugin           => $neutron_core_plugin
  }

  neutron_config {
    'database/connection': value => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron";
  }

  class { '::neutron::keystone::auth':
    password         => $neutron_user_password,
    public_address   => $controller_pub_floating_ip,
    admin_address    => $controller_priv_floating_ip,
    internal_address => $controller_priv_floating_ip,
  }

  class { '::neutron::server':
    auth_host        => $::ipaddress,
    auth_password    => $neutron_user_password,
  }

  if $neutron_core_plugin == 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2' {
    neutron_plugin_ovs {
      'OVS/enable_tunneling': value => 'True';
      'SECURITYGROUP/firewall_driver':
      value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
    }

    class { '::neutron::plugins::ovs':
      sql_connection      => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron",
      tenant_network_type => $tenant_network_type,
    }
  }

  if $neutron_core_plugin == 'neutron.plugins.cisco.network_plugin.PluginV2' {
    class { 'quickstack::neutron::plugins::cisco':
      neutron_db_password          => $neutron_db_password,
      neutron_user_password        => $neutron_user_password,
      bridge_interface             => $bridge_interface,
      ovs_vlan_ranges              => $ovs_vlan_ranges,
      cisco_vswitch_plugin         => $cisco_vswitch_plugin,
      nexus_config                 => $nexus_config,
      cisco_nexus_plugin           => $cisco_nexus_plugin,
      nexus_credentials            => $nexus_credentials,
      provider_vlan_auto_create    => $provider_vlan_auto_create,
      provider_vlan_auto_trunk     => $provider_vlan_auto_trunk,
      mysql_host                   => $mysql_host,
      tenant_network_type          => $tenant_network_type,
    }
  }

  class { '::nova::network::neutron':
    neutron_admin_password    => $neutron_user_password,
  }

  firewall { '001 neutron server (API)':
    proto    => 'tcp',
    dport    => ['9696'],
    action   => 'accept',
  }
}
