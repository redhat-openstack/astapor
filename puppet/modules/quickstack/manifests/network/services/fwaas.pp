#
class quickstack::network::services::fwaas {
  class { '::neutron::services::fwaas': }
}
