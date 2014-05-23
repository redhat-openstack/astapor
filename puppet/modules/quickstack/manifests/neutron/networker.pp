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
  $mysql_host                    = $quickstack::params::mysql_host,
  $nagios                        = $quickstack::params::nagios,
  $nagios_local_iface            = $quickstack::params::nagios_local_iface,
  $nagios_server_ip              = $quickstack::params::nagios_server_ip,
  $qpid_host                     = $quickstack::params::qpid_host,
  $external_network_bridge       = 'br-ex',
  $qpid_username                 = $quickstack::params::qpid_username,
  $qpid_password                 = $quickstack::params::qpid_password,
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
    $qpid_port = '5671'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron?ssl_ca=${mysql_ca}"
  } else {
    $qpid_protocol = 'tcp'
    $qpid_port = '5672'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron"
  }

  class { '::neutron':
    verbose               => true,
    allow_overlapping_ips => true,
    rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
    qpid_hostname         => $qpid_host,
    qpid_protocol         => $qpid_protocol,
    qpid_port             => $qpid_port,
    qpid_username         => $qpid_username,
    qpid_password         => $qpid_password,
  }

  class { '::neutron::plugins::ovs':
    sql_connection      => $sql_connection,
    tenant_network_type => $tenant_network_type,
    network_vlan_ranges => $ovs_vlan_ranges,
    tunnel_id_ranges    => $tunnel_id_ranges,
    vxlan_udp_port      => $ovs_vxlan_udp_port,
  }

  $local_ip = find_ip("$ovs_tunnel_network","$ovs_tunnel_iface","")

  class { '::neutron::agents::ovs':
    bridge_uplinks   => $ovs_bridge_uplinks,
    local_ip         => $local_ip,
    bridge_mappings  => $ovs_bridge_mappings,
    enable_tunneling => str2bool_i("$enable_tunneling"),
    tunnel_types     => $ovs_tunnel_types,
    vxlan_udp_port   => $ovs_vxlan_udp_port,
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

  class { '::neutron::server':
    auth_host      => $controller_priv_host,
    auth_password  => $neutron_user_password,
    auth_tenant    => 'services',
    auth_user      => 'neutron',
    connection     => $sql_connection,
  }

  class { '::neutron::server::notifications':
    notify_nova_on_port_status_changes => true,
    notify_nova_on_port_data_changes   => true,
    nova_url                           => "http://${controller_priv_host}:8774/v2",
    nova_admin_auth_url                => "http://${controller_priv_host}:35357/v2.0",
    nova_admin_username                => "nova",
    nova_admin_password                => "${nova_user_password}",
  }

  #class { 'neutron::agents::lbaas': }

  #class { 'neutron::agents::fwaas': }

  class {'quickstack::neutron::firewall::vxlan':
    port => $ovs_vxlan_udp_port,
  }

  if str2bool_i("$nagios"){
    class {'quickstack::monitor::nagios::client':
      host_ip          => getvar("ipaddress_${nagios_local_iface}"),
      nagios_server_ip => $nagios_server_ip,
    }
  }
}
