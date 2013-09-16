class quickstack::neutron::public_network (
  $allocation_pools_start = $quickstack::neutron::public_network_params::allocation_pools_start,
  $allocation_pools_end   = $quickstack::neutron::public_network_params::allocation_pools_end,
  $cidr                   = $quickstack::neutron::public_network_params::cidr,
  $gateway_ip             = $quickstack::neutron::public_network_params::gateway_ip,
  $network_name           = $quickstack::neutron::public_network_params::network_name,
  $tenant_name            = 'admin',
  $router_external        = 'True',
) inherits quickstack::neutron::public_network_params {

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