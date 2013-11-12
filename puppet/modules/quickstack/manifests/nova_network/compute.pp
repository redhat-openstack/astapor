# Quickstack compute node configuration for nova network
class quickstack::nova_network::compute (
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip  = $quickstack::params::controller_pub_floating_ip,
  $fixed_network_range         = $quickstack::params::fixed_network_range,
  $floating_network_range      = $quickstack::params::floating_network_range,
  $private_interface           = $quickstack::params::private_interface,
  $public_interface            = $quickstack::params::public_interface,
) inherits quickstack::params {

  # Configure Nova
  nova_config{
    'DEFAULT/auto_assign_floating_ip':  value => 'True';
    #"DEFAULT/network_host":            value => ${controller_priv_floating_ip;
    "DEFAULT/network_host":             value => "$::ipaddress";
    #"DEFAULT/metadata_host":           value => "$controller_priv_floating_ip";
    "DEFAULT/metadata_host":            value => "$::ipaddress";
    "DEFAULT/multi_host":               value => "True";
  }

  class { 'nova::network':
    private_interface => "$private_interface",
    public_interface  => "$public_interface",
    fixed_range       => "$fixed_network_range",
    floating_range    => "$floating_network_range",
    network_manager   => "nova.network.manager.FlatDHCPManager",
    config_overrides  => {"force_dhcp_release" => false},
    create_networks   => true,
    enabled           => true,
    install_service   => true,
  }
}
