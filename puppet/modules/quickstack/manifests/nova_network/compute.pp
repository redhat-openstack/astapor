# Quickstack compute node configuration for nova network
class quickstack::nova_network::compute (
  $admin_password               = $quickstack::params::admin_password,
  $ceilometer_metering_secret   = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password     = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster       = $quickstack::params::cinder_backend_gluster,
  $controller_priv_floating_ip  = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip   = $quickstack::params::controller_pub_floating_ip,
  $fixed_network_range          = $quickstack::params::fixed_network_range,
  $floating_network_range       = $quickstack::params::floating_network_range,
  $mysql_host                   = $quickstack::params::mysql_host,
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $private_interface            = $quickstack::params::private_interface,
  $public_interface             = $quickstack::params::public_interface,
  $qpid_host                    = $quickstack::params::qpid_host,
  $qpid_username                = $quickstack::params::qpid_username,
  $qpid_password                = $quickstack::params::qpid_password,
  $verbose                      = $quickstack::params::verbose,

  $auto_assign_floating_ip
) inherits quickstack::params {

  # Configure Nova
  nova_config{
    'DEFAULT/auto_assign_floating_ip':  value => $auto_assign_floating_ip;
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


  class { 'quickstack::compute_common':
    admin_password              => $admin_password,
    ceilometer_metering_secret  => $ceilometer_metering_secret,
    ceilometer_user_password    => $ceilometer_user_password,
    cinder_backend_gluster      => $cinder_backend_gluster,
    controller_priv_floating_ip => $controller_priv_floating_ip,
    controller_pub_floating_ip  => $controller_pub_floating_ip,
    mysql_host                  => $mysql_host,
    nova_db_password            => $nova_db_password,
    nova_user_password          => $nova_user_password,
    qpid_host                   => $qpid_host,
    qpid_username               => $qpid_username,
    qpid_password               => $qpid_password,
    verbose                     => $verbose,
  }
}
