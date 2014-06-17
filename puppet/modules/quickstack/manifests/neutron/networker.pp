# Quickstack network node configuration for neutron (OpenStack Networking)
class quickstack::neutron::networker (
  $fixed_network_range           = $quickstack::params::fixed_network_range,
  $neutron_metadata_proxy_secret = $quickstack::params::neutron_metadata_proxy_secret,
  $neutron_db_password           = $quickstack::params::neutron_db_password,
  $neutron_user_password         = $quickstack::params::neutron_user_password,
  $nova_db_password              = $quickstack::params::nova_db_password,
  $nova_user_password            = $quickstack::params::nova_user_password,
  $controller_priv_host          = $quickstack::params::controller_priv_host,
  $ovs_tunnel_iface              = 'eth1',
  $ovs_tunnel_network            = '',
  $ovs_l2_population             = 'True',
  $mysql_host                    = $quickstack::params::mysql_host,
  $amqp_provider                 = $quickstack::params::amqp_provider,
  $amqp_host                     = $quickstack::params::amqp_host,
  $external_network_bridge       = 'br-ex',
  $amqp_username                 = $quickstack::params::amqp_username,
  $amqp_password                 = $quickstack::params::amqp_password,
  $tenant_network_type           = $quickstack::params::tenant_network_type,
  $ovs_bridge_mappings           = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks            = $quickstack::params::ovs_bridge_uplinks,
  $ovs_vlan_ranges               = $quickstack::params::ovs_vlan_ranges,
  $tunnel_id_ranges              = '1:1000',
  $ovs_vxlan_udp_port            = $quickstack::params::ovs_vxlan_udp_port,
  $ovs_tunnel_types              = $quickstack::params::ovs_tunnel_types,
  $enable_tunneling              = $quickstack::params::enable_tunneling,
  $verbose                       = $quickstack::params::verbose,
  $ssl                           = $quickstack::params::ssl,
  $mysql_ca                      = $quickstack::params::mysql_ca,
) inherits quickstack::params {

  class {'quickstack::openstack_common': }

  if str2bool_i("$ssl") {
    $qpid_protocol = 'ssl'
    $amqp_port = '5671'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron?ssl_ca=${mysql_ca}"
  } else {
    $qpid_protocol = 'tcp'
    $amqp_port = '5672'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron"
  }

  class { '::neutron':
    verbose               => true,
    allow_overlapping_ips => true,
    rpc_backend           => amqp_backend('neutron', $amqp_provider),
    qpid_hostname         => $amqp_host,
    qpid_protocol         => $qpid_protocol,
    qpid_port             => $amqp_port,
    qpid_username         => $amqp_username,
    qpid_password         => $amqp_password,
    rabbit_host           => $amqp_host,
    rabbit_port           => $amqp_port,
    rabbit_user           => $amqp_username,
    rabbit_password       => $amqp_password,
  }

  neutron_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/admin_tenant_name': value => 'services';
    'keystone_authtoken/admin_user':        value => 'neutron';
    'keystone_authtoken/admin_password':    value => $neutron_user_password;
  }

  class { 'quickstack::neutron::controller':
    neutron_core_plugin  => $quickstack::neutron::controller::neutron_core_plugin;
  }

  if $neutron_core_plugin == 'neutron.plugins.cisco.network_plugin.PluginV2' {
    if (!defined(Package['neutron-plugin-ovs'])) {
      package { 'neutron-plugin-ovs':
        ensure => present,
        name   => $::neutron::params::ovs_server_package,
      }
    }
  } else {
    class { '::neutron::plugins::ovs':
      sql_connection      => $sql_connection,
      tenant_network_type => $tenant_network_type,
      network_vlan_ranges => $ovs_vlan_ranges,
      tunnel_id_ranges    => $tunnel_id_ranges,
      vxlan_udp_port      => $ovs_vxlan_udp_port,
    }

    neutron_plugin_ovs { 'AGENT/l2_population': value => "$ovs_l2_population"; }

    $local_ip = find_ip("$ovs_tunnel_network","$ovs_tunnel_iface","")

    class { '::neutron::agents::ovs':
      bridge_uplinks   => $ovs_bridge_uplinks,
      local_ip         => $local_ip,
      bridge_mappings  => $ovs_bridge_mappings,
      enable_tunneling => str2bool_i("$enable_tunneling"),
      tunnel_types     => $ovs_tunnel_types,
      vxlan_udp_port   => $ovs_vxlan_udp_port,
    }
  }

  class { '::neutron::agents::dhcp': }

  class { '::neutron::agents::l3':
    external_network_bridge => $external_network_bridge,
  }

  class { 'neutron::agents::metadata':
    auth_password => $neutron_user_password,
    shared_secret => $neutron_metadata_proxy_secret,
    auth_url      => "http://${controller_priv_host}:35357/v2.0",
    metadata_ip   => $controller_priv_host,
  }

  #class { 'neutron::agents::lbaas': }

  #class { 'neutron::agents::fwaas': }

  class {'quickstack::neutron::firewall::gre':}

  class {'quickstack::neutron::firewall::vxlan':
    port => $ovs_vxlan_udp_port,
  }
}
