
class quickstack::neutron::public_network_params {
  $network_name           = 'public'
  $cidr                   = '10.16.16.0/22'
  $gateway_ip             = '10.16.19.254'
  $allocation_pools_start = '10.16.18.1'
  $allocation_pools_end   = '10.16.18.254'
}
