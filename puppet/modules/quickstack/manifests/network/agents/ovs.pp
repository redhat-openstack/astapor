#
class quickstack::network::agents::ovs (
$bridge_mappings,
$bridge_uplinks,
$enable_tunneling,
) inherits quickstack::network::params {

  $local_ip = find_ip("$tunnel_network",
                    ["$tunnel_iface","$external_network_bridge"],
                    "")

  class { '::neutron::agents::ovs':
    bridge_mappings  => $bridge_mappings,
    bridge_uplinks   => $bridge_uplinks,
    enabled          => opposite_state("$pcs_setup_neutron"),
    enable_tunneling => str2bool_i("$enable_tunneling"),
    local_ip         => $local_ip,
    manage_service   => opposite_state("$pcs_setup_neutron"),
    tunnel_types     => $tunnel_types,
    vxlan_udp_port   => $vxlan_udp_port,
    veth_mtu         => $veth_mtu,
  }
  ->
  class {'quickstack::firewall::network::tunnels':}
}
