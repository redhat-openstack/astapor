# Quickstack compute node configuration for nova network
class quickstack::nova_network::compute (
  $admin_password               = $quickstack::params::admin_password,
  $ceilometer                   = 'true',
  $ceilometer_host              = 'false',
  $ceilometer_metering_secret   = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password     = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster       = $quickstack::params::cinder_backend_gluster,
  $controller_priv_host         = $quickstack::params::controller_priv_host,
  $controller_pub_host          = $quickstack::params::controller_pub_host,
  $mysql_host                   = $quickstack::params::mysql_host,
  $auto_assign_floating_ip      = 'True',
  $nova_multi_host              = 'True',
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $network_private_iface        = 'eth1',
  $network_private_network      = '192.168.200.0',
  $network_public_iface         = 'eth2',
  $network_public_network       = '192.168.201.0',
  $network_manager              = 'FlatDHCPManager',
  $network_create_networks      = true,
  $network_num_networks         = 1,
  $network_network_size         = 255,
  $network_overrides            = {"force_dhcp_release" => false},
  $network_fixed_range          = '10.0.0.0/24',
  $network_floating_range       = '10.0.0.0/24',
  $ntp_servers                  = ['0.pool.ntp.org','1.pool.ntp.org','2.pool.ntp.org'],
  $qpid_host                    = $quickstack::params::qpid_host,
  $qpid_username                = $quickstack::params::qpid_username,
  $qpid_password                = $quickstack::params::qpid_password,
  $verbose                      = $quickstack::params::verbose,
  $ssl                          = $quickstack::params::ssl,
  $mysql_ca                     = $quickstack::params::mysql_ca,
  $use_qemu_for_poc             = $quickstack::params::use_qemu_for_poc,
) inherits quickstack::params {

  # Configure Nova
  nova_config{
    'DEFAULT/auto_assign_floating_ip':  value => "$auto_assign_floating_ip";
    "DEFAULT/network_host":             value => "$::ipaddress";
    "DEFAULT/metadata_host":            value => "$::ipaddress";
    "DEFAULT/multi_host":               value => "$nova_multi_host";
  }

  nova::generic_service { 'metadata-api':
    enabled        => true,
    ensure_package => 'present',
    package_name   => 'openstack-nova-api',
    service_name   => 'openstack-nova-metadata-api',
  }

  $priv_nic = find_nic("$network_private_network","$network_private_iface","")
  $pub_nic = find_nic("$network_public_network","$network_public_iface","")

  class { '::nova::network':
    private_interface => "$priv_nic",
    public_interface  => "$pub_nic",
    fixed_range       => "$network_fixed_range",
    num_networks      => $network_num_networks,
    network_size      => $network_network_size,
    floating_range    => "$network_floating_range",
    enabled           => true,
    network_manager   => "nova.network.manager.$network_manager",
    config_overrides  => $network_overrides,
    create_networks   => $network_create_networks,
    install_service   => true,
  }

  class { 'quickstack::compute_common':
    admin_password             => $admin_password,
    ceilometer                 => $ceilometer,
    ceilometer_host            => $ceilometer_host,
    ceilometer_metering_secret => $ceilometer_metering_secret,
    ceilometer_user_password   => $ceilometer_user_password,
    cinder_backend_gluster     => $cinder_backend_gluster,
    controller_priv_host       => $controller_priv_host,
    controller_pub_host        => $controller_pub_host,
    mysql_host                 => $mysql_host,
    nova_db_password           => $nova_db_password,
    nova_user_password         => $nova_user_password,
    ntp_servers                => $ntp_servers,
    qpid_host                  => $qpid_host,
    qpid_username              => $qpid_username,
    qpid_password              => $qpid_password,
    verbose                    => $verbose,
    ssl                        => $ssl,
    mysql_ca                   => $mysql_ca,
    use_qemu_for_poc           => $use_qemu_for_poc,
  }
}
