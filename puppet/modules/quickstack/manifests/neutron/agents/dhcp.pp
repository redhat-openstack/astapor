#
class quickstack::neutron::agents::dhcp (
) inherits quickstack::params {
  # Logical ID for the a network node to deploy several Active/Passive services
  # To Remove when adding neutron-scale feature
  neutron_config {
    'DEFAULT/host': value => 'neutron-n-0';
  }

  class { '::neutron::agents::dhcp':
    enabled        => opposite_state("$quickstack::params::pcs_setup_neutron"),
    manage_service => opposite_state("$quickstack::params::pcs_setup_neutron"),
  }
}
