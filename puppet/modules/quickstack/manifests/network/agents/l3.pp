#
class quickstack::network::agents::l3 (
) inherits quickstack::network::params {

  class { '::neutron::agents::l3':
    external_network_bridge => $external_network_bridge,
    enabled        => opposite_state("$pcs_setup_neutron"),
    manage_service => opposite_state("$pcs_setup_neutron"),
  }
}
