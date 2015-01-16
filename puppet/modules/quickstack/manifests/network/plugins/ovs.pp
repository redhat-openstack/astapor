class quickstack::network::plugins::ovs (
  $sql_connection,
  $l2_population,
  $tenant_network_type,
  $tunnel_id_ranges,
  $vlan_ranges,
) inherits quickstack::network::params {

  class { '::neutron::plugins::ovs':
    sql_connection      => $sql_connection,
    tenant_network_type => $tenant_network_type,
    network_vlan_ranges => $vlan_ranges,
    tunnel_id_ranges    => $tunnel_id_ranges,
    vxlan_udp_port      => $vxlan_udp_port,
  }

  neutron_plugin_ovs { 'AGENT/l2_population': value => "$l2_population"; }
}
