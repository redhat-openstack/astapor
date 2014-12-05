class quickstack::roles::neutron::plugins::ovs (
  $ovs_l2_population,
) inherits quickstack::neutron::params {

  class { '::neutron::plugins::ovs':
    sql_connection      => $sql_connection,
    tenant_network_type => $ovs_tenant_network_type,
    network_vlan_ranges => $ovs_vlan_ranges,
    tunnel_id_ranges    => $ovs_tunnel_id_ranges,
    vxlan_udp_port      => $ovs_vxlan_udp_port,
  }

  neutron_plugin_ovs { 'AGENT/l2_population': value => "$ovs_l2_population"; }
}
