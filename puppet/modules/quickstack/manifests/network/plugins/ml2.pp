class quickstack::network::plugins::ml2 (
  $flat_networks,
  $mechanism_drivers,
  $network_vlan_ranges,
  $security_group,
  $tenant_network_types,
  $tunnel_id_ranges,
  $type_drivers,
  $vxlan_group,
  $vni_ranges,
) inherits quickstack::network::params {

 if $neutron_core_plugin == 'neutron.plugins.ml2.plugin.Ml2Plugin' {
  #  neutron_config {
  #    'DEFAULT/service_plugins':
  #      value => join(['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',]),
  #  }
  #  ->
    class { '::neutron::plugins::ml2':
      type_drivers          => $type_drivers,
      tenant_network_types  => $tenant_network_types,
      mechanism_drivers     => $mechanism_drivers,

      flat_networks         => $flat_networks,
      network_vlan_ranges   => $network_vlan_ranges,
      tunnel_id_ranges      => $tunnel_id_ranges,
      vxlan_group           => $vxlan_group,
      vni_ranges            => $vni_ranges,
      enable_security_group => str2bool_i("$security_group"),
      require               => Class['neutron'],
    }

    # If cisco nexus is part of ml2 mechanism drivers,
    # setup Mech Driver Cisco Neutron plugin class.
    if ('cisco_nexus' in $mechanism_drivers) {
      class { 'neutron::plugins::ml2::cisco::nexus':
        nexus_config => $nexus_config,
      }
    }
  }
}
