#
class quickstack::roles::neutron::agents::ml2::ovs (
$bridge_uplinks,
$bridge_mappings,
$enable_tunneling,
$l2_population,
$tunnel_iface,
$tunnel_network,
$tunnel_types,
) inherits quickstack::roles::params {

  $local_ip = find_ip("$tunnel_network","$tunnel_iface","")

  class { '::neutron::agents::ml2::ovs':
    bridge_uplinks        => $bridge_uplinks,
    bridge_mappings       => $bridge_mappings,
    enable_tunneling      => $enable_tunneling,
    tunnel_types          => $tunnel_types,
    local_ip              => "$local_ip",
    vxlan_udp_port        => 4789,
    polling_interval      => 2,
    l2_population         => $l2_population,
  }
}
