# Quickstack network node configuration for neutron (OpenStack Networking)
class quickstack::neutron::networker (
  $fixed_network_range           = $quickstack::params::fixed_network_range,
  $neutron_metadata_proxy_secret = $quickstack::params::neutron_metadata_proxy_secret,
  $neutron_db_password           = $quickstack::params::neutron_db_password,
  $neutron_user_password         = $quickstack::params::neutron_user_password,
  $nova_db_password              = $quickstack::params::nova_db_password,
  $nova_user_password            = $quickstack::params::nova_user_password,
  $controller_priv_host          = $quickstack::params::controller_priv_host,
  $ovs_tunnel_iface              = 'em1',
  $mysql_host                    = $quickstack::params::mysql_host,
  $qpid_host                     = $quickstack::params::qpid_host,
  $external_network_bridge       = 'br-ex',
  $tenant_network_type           = $quickstack::params::tenant_network_type,
  $ovs_bridge_mappings           = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks            = $quickstack::params::ovs_bridge_uplinks,
  $ovs_vlan_ranges               = $quickstack::params::ovs_vlan_ranges,
  $tunnel_id_ranges              = '1:1000',
  $enable_tunneling              = $quickstack::params::enable_tunneling,
  $verbose                       = $quickstack::params::verbose,
  $ssl                           = $quickstack::params::ssl,
  $mysql_ca                      = $quickstack::params::mysql_ca,
) inherits quickstack::params {

  # str2bool expects the string to already be downcased.  all-righty.
  # (i.e. str2bool('True') would blow up, so work around it.)
  $enable_tunneling_bool = $enable_tunneling ? {
      /(?i:true)/   => true,
      /(?i:false)/  => false,
      default => str2bool("$enable_tunneling"),
  }

  if str2bool($ssl) == true {
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
  }

  neutron_config {
    'database/connection': value => $sql_connection;
    'keystone_authtoken/admin_tenant_name': value => 'services';
    'keystone_authtoken/admin_user':        value => 'neutron';
    'keystone_authtoken/admin_password':    value => $neutron_user_password;
    'keystone_authtoken/auth_host':         value => $controller_priv_host;
  }

  class { '::neutron::plugins::ovs':
    sql_connection      => $sql_connection,
    tenant_network_type => $tenant_network_type,
    network_vlan_ranges => $ovs_vlan_ranges,
    tunnel_id_ranges    => $tunnel_id_ranges,
  }

  class { '::neutron::agents::ovs':
    bridge_uplinks      => $ovs_bridge_uplinks,
    local_ip            => getvar("ipaddress_${ovs_tunnel_iface}"),
    bridge_mappings     => $ovs_bridge_mappings,
    enable_tunneling    => $enable_tunneling_bool,
  }

  class { '::neutron::agents::dhcp': }

  class { '::neutron::agents::l3':
    external_network_bridge => $external_network_bridge,
  }

  class { 'neutron::agents::metadata':
    auth_password => $admin_password,
    shared_secret => $neutron_metadata_proxy_secret,
    auth_url      => "http://${controller_priv_host}:35357/v2.0",
    metadata_ip   => $controller_priv_host,
  }

  #class { 'neutron::agents::lbaas': }

  #class { 'neutron::agents::fwaas': }
}
