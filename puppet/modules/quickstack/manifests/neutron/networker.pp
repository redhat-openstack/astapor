# Quickstack network node configuration for neutron (OpenStack Networking)
class quickstack::neutron::networker (
  $configure_ovswitch            = $quickstack::params::configure_ovswitch,
  $fixed_network_range           = $quickstack::params::fixed_network_range,
  $neutron_metadata_proxy_secret = $quickstack::params::neutron_metadata_proxy_secret,
  $neutron_db_password           = $quickstack::params::neutron_db_password,
  $neutron_user_password         = $quickstack::params::neutron_user_password,
  $nova_db_password              = $quickstack::params::nova_db_password,
  $nova_user_password            = $quickstack::params::nova_user_password,
  $controller_priv_floating_ip   = $quickstack::params::controller_priv_floating_ip,
  $private_interface             = $quickstack::params::private_interface,
  $public_interface              = $quickstack::params::public_interface,
  $mysql_host                    = $quickstack::params::mysql_host,
  $qpid_host                     = $quickstack::params::qpid_host,
  $qpid_username                 = $quickstack::params::qpid_username,
  $qpid_password                 = $quickstack::params::qpid_password,
  $bridge_name                   = 'br-ex',
  $bridge_keep_ip                = true,
  $tenant_network_type           = $quickstack::params::tenant_network_type,
  $ovs_bridge_mappings           = $quickstack::params::ovs_bridge_mappings,
  $ovs_vlan_ranges               = $quickstack::params::ovs_vlan_ranges,
  $tunnel_id_ranges              = '1:1000',
  $enable_tunneling              = $quickstack::params::enable_tunneling,
  $verbose                       = $quickstack::params::verbose,
) inherits quickstack::params {

  # str2bool expects the string to already be downcased.  all-righty.
  # (i.e. str2bool('True') would blow up, so work around it.)
  $enable_tunneling_bool = $enable_tunneling ? {
      /(?i:true)/   => true,
      /(?i:false)/  => false,
      default => str2bool("$enable_tunneling"),
  }

  if str2bool("$configure_ovswitch") {
    vs_bridge { $bridge_name:
      provider => ovs_redhat,
      ensure   => present,
    } ->
    vs_port { 'external':
      bridge    => $bridge_name,
      interface => $public_interface,
      keep_ip   => $bridge_keep_ip,
      sleep     => '30',
      provider  => ovs_redhat,
      ensure    => present,
    }
  }

  class { '::neutron':
    verbose               => true,
    allow_overlapping_ips => true,
    rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
    qpid_hostname         => $qpid_host,
    qpid_username         => $qpid_username,
    qpid_password         => $qpid_password,
  }

  neutron_config {
    'database/connection': value => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron";
    'keystone_authtoken/admin_tenant_name': value => 'services';
    'keystone_authtoken/admin_user':        value => 'neutron';
    'keystone_authtoken/admin_password':    value => $neutron_user_password;
    'keystone_authtoken/auth_host':         value => $controller_priv_floating_ip;
  }

  class { '::neutron::plugins::ovs':
    sql_connection      => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron",
    tenant_network_type => $tenant_network_type,
    network_vlan_ranges => $ovs_vlan_ranges,
    tunnel_id_ranges    => $tunnel_id_ranges,
  }

  class { '::neutron::agents::ovs':
    local_ip            => getvar("ipaddress_${private_interface}"),
    bridge_mappings     => $ovs_bridge_mappings,
    enable_tunneling    => $enable_tunneling_bool,
  }

  class { '::neutron::agents::dhcp': }

  class { '::neutron::agents::l3': }

  class { 'neutron::agents::metadata':
    auth_password => $admin_password,
    shared_secret => $neutron_metadata_proxy_secret,
    auth_url      => "http://${controller_priv_floating_ip}:35357/v2.0",
    metadata_ip   => $controller_priv_floating_ip,
  }

  #class { 'neutron::agents::lbaas': }

  #class { 'neutron::agents::fwaas': }
}
