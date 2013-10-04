class quickstack::neutron::network_public (
  $allocation_pools_start = $quickstack::params::allocation_pools_start,
  $allocation_pools_end   = $quickstack::params::allocation_pools_end,
  $cidr                   = $quickstack::params::cidr,
  $gateway_ip             = $quickstack::params::gateway_ip,
  $network_name           = $quickstack::params::network_name,
  $tenant_name            = 'admin',
  $router_external        = 'True',
) inherits quickstack::params {

    neutron_network { 'public':
        ensure          => present,
        router_external => $router_external,
        tenant_name     => $tenant_name,
    }

    neutron_subnet { 'public_subnet':
        ensure           => 'present',
        cidr             => $cidr,
        gateway_ip       => $gateway_ip,
        allocation_pools => "start=${allocation_pools_start},end=${allocation_pools_end}",
        network_name     => $network_name,
        tenant_name      => $tenant_name,
    }
}
