#
class quickstack::network::agents::lbaas {
  class { '::neutron::agents::lbaas': }
}
