class quickstack::firewall::network::tunnels (
  $tunnel_types_details,
) {

  include quickstack::firewall::common

  $default = {
    'ensure' => present,
    'action' => 'accept'
  }

    # Todo: add function to filter out unused tunnels types
  create_resources ('firewall', $tunnel_types_details, $default)
}
