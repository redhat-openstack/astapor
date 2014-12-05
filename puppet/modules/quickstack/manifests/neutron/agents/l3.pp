#
class quickstack::neutron::agents::l3 (
) inherits quickstack::params {

  class { '::neutron::agents::l3':
    external_network_bridge => $external_network_bridge,
    enabled        => opposite_state("$quickstack::params::pcs_setup_neutron"),
    manage_service => opposite_state("$quickstack::params::pcs_setup_neutron"),
  }
}
