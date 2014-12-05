class quickstack::neutron::plugins::ml2 (
) inherits quickstack::params {

 if $neutron_core_plugin == 'neutron.plugins.ml2.plugin.Ml2Plugin' {
  #  neutron_config {
  #    'DEFAULT/service_plugins':
  #      value => join(['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',]),
  #  }
  #  ->
    class { '::neutron::plugins::ml2':
      type_drivers          => $ml2_type_drivers,
      tenant_network_types  => $ml2_tenant_network_types,
      mechanism_drivers     => $ml2_mechanism_drivers,

      flat_networks         => $ml2_flat_networks,
      network_vlan_ranges   => $ml2_network_vlan_ranges,
      tunnel_id_ranges      => $ml2_tunnel_id_ranges,
      vxlan_group           => $ml2_vxlan_group,
      vni_ranges            => $ml2_vni_ranges,
      enable_security_group => str2bool_i("$ml2_security_group"),
      require               => Class['neutron'],
    }

    # If cisco nexus is part of ml2 mechanism drivers,
    # setup Mech Driver Cisco Neutron plugin class.
    if ('cisco_nexus' in $ml2_mechanism_drivers) {
      class { 'neutron::plugins::ml2::cisco::nexus':
        nexus_config => $nexus_config,
      }
    }
  }
