#
class quickstack::roles::neutron::agents::dhcp (
  $manage_service = true,
) {
  class { '::neutron::agents::dhcp':
    enabled        => 'true',
    manage_service => $manage_service,
  }
}
