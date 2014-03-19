class quickstack::pacemaker::load_balancer (
  $ha_loadbalancer_public_vip  = $quickstack::params::ha_loadbalancer_public_vip,
  $ha_loadbalancer_private_vip = $quickstack::params::ha_loadbalancer_private_vip,
  $ha_loadbalancer_group       = $quickstack::params::ha_loadbalancer_group,
) inherits quickstack::params {

  pacemaker::resource::ip { "ip-$ha_loadbalancer_public_vip":
    ip_address => "$ha_loadbalancer_public_vip",
    group      => "$ha_loadbalancer_group",
  }
  ->
  pacemaker::resource::ip { "ip-$ha_loadbalancer_private_vip":
    ip_address => "$ha_loadbalancer_private_vip",
    group      => "$ha_loadbalancer_group",
  }
  ->
  pacemaker::resource::lsb {'haproxy':
    group => "$ha_loadbalancer_group",
    clone => true,
  }

  Class['::quickstack::load_balancer'] ->
  Class['::quickstack::pacemaker::common'] ->
  Class['::quickstack::pacemaker::load_balancer']
}
