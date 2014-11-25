#
class quickstack::roles::neutron::agents::l3 (
  $ext_network_bridge,
  $manage_service = true,
) {
  class { '::neutron::agents::l3':
    enabled                 => 'true',
    external_network_bridge => $ext_network_bridge,
    manage_service          => $manage_service,
  }
}
