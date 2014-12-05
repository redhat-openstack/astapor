class quickstack::firewall::neutron::tunnels (
) inherits quickstack::params {

  include quickstack::firewall::common

  $default = {
    ensure => present,
    action => 'accept'
  }

  create_resource ('firewall', $ovs_tunnel_types_details, $default )
}
