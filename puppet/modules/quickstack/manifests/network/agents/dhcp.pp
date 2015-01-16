#
class quickstack::network::agents::dhcp (
) inherits quickstack::network::params {

  # Logical ID for the a network node to deploy several Active/Passive services
  # To Remove when adding neutron-scale feature
  neutron_config {
    'DEFAULT/host': value => 'neutron-n-0';
  }

  class { '::neutron::agents::dhcp':
    enabled        => opposite_state("$pcs_setup_neutron"),
    manage_service => opposite_state("$pcs_setup_neutron"),
  }
}
