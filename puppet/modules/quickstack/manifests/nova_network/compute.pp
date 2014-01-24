# Quickstack compute node configuration for nova network
class quickstack::nova_network::compute (
  $admin_password               = $quickstack::params::admin_password,
  $ceilometer_metering_secret   = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password     = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster       = $quickstack::params::cinder_backend_gluster,
  $controller_priv_host         = $quickstack::params::controller_priv_host,
  $controller_pub_host          = $quickstack::params::controller_pub_host,
  $fixed_network_range          = $quickstack::params::fixed_network_range,
  $floating_network_range       = $quickstack::params::floating_network_range,
  $mysql_host                   = $quickstack::params::mysql_host,
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $nova_network_private_iface   = 'em1',
  $nova_network_public_iface    = 'em2',
  $qpid_host                    = $quickstack::params::qpid_host,
  $verbose                      = $quickstack::params::verbose,
  $ssl                          = $quickstack::params::ssl,
  $mysql_ca                     = $quickstack::params::mysql_ca,

  $auto_assign_floating_ip
) inherits quickstack::params {

  # Configure Nova
  nova_config{
    'DEFAULT/auto_assign_floating_ip':  value => $auto_assign_floating_ip;
    "DEFAULT/network_host":             value => "$::ipaddress";
    "DEFAULT/metadata_host":            value => "$::ipaddress";
    "DEFAULT/multi_host":               value => "True";
  }

  nova::generic_service { 'metadata-api':
    enabled        => true,
    ensure_package => 'present',
    package_name   => 'openstack-nova-api',
    service_name   => 'openstack-nova-metadata-api',
  }
  
  class { 'nova::network':
    private_interface => "$nova_network_private_iface",
    public_interface  => "$nova_network_public_iface",
    fixed_range       => "$fixed_network_range",
    floating_range    => "$floating_network_range",
    network_manager   => "nova.network.manager.FlatDHCPManager",
    config_overrides  => {"force_dhcp_release" => false},
    create_networks   => true,
    enabled           => true,
    install_service   => true,
  }

  class { 'quickstack::compute_common':
    admin_password              => $admin_password,
    ceilometer_metering_secret  => $ceilometer_metering_secret,
    ceilometer_user_password    => $ceilometer_user_password,
    cinder_backend_gluster      => $cinder_backend_gluster,
    controller_priv_host        => $controller_priv_host,
    controller_pub_host         => $controller_pub_host,
    mysql_host                  => $mysql_host,
    nova_db_password            => $nova_db_password,
    nova_user_password          => $nova_user_password,
    qpid_host                   => $qpid_host,
    verbose                     => $verbose,
    ssl                         => $ssl,
    mysql_ca                    => $mysql_ca,
  }
}
