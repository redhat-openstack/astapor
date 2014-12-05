#
class quickstack::neutron::agents::ovs (
$bridge_uplinks,
$bridge_mappings,
$enable_tunneling,
$l2_population,
$ovs_tunnel_iface,
$ovs_tunnel_network,
$ovs_tunnel_types,
) inherits quickstack::params {

  $local_ip = find_ip("$ovs_tunnel_network",
                    ["$ovs_tunnel_iface","$external_network_bridge"],
                    "")

  class { '::neutron::agents::ovs':
    bridge_mappings  => $ovs_bridge_mappings,
    bridge_uplinks   => $ovs_bridge_uplinks,
    enabled          => pcs_manage_neutron,
    enable_tunneling => str2bool_i("$enable_tunneling"),
    local_ip         => $local_ip,
    manage_service   => pcs_manage_neutron,
    tunnel_types     => $ovs_tunnel_types,
    vxlan_udp_port   => $ovs_vxlan_udp_port,
    veth_mtu         => $veth_mtu,
  } -> class {'quickstack::firewall::neutron::tunnels':}

}
