# Quickstart class for nova network controller
class quickstack::nova_network::controller (
  $admin_email                   = $quickstack::params::admin_email,
  $admin_password                = $quickstack::params::admin_password,
  $ceilometer_metering_secret    = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password      = $quickstack::params::ceilometer_user_password,
  $cinder_enabled_backends       = $quickstack::params::cinder_enabled_backends,
  $cinder_backend_gluster        = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_gluster_name   = $quickstack::params::cinder_backend_gluster_name,
  $cinder_backend_eqlx           = $quickstack::params::cinder_backend_eqlx,
  $cinder_backend_eqlx_name      = $quickstack::params::cinder_backend_eqlx_name,
  $cinder_backend_iscsi          = $quickstack::params::cinder_backend_iscsi,
  $cinder_backend_iscsi_name     = $quickstack::params::cinder_backend_iscsi_name,
  $cinder_db_password            = $quickstack::params::cinder_db_password,
  $cinder_gluster_servers        = $quickstack::params::cinder_gluster_servers,
  $cinder_san_ip                 = $quickstack::params::cinder_san_ip,
  $cinder_san_login              = $quickstack::params::cinder_san_login,
  $cinder_san_password           = $quickstack::params::cinder_san_password,
  $cinder_san_thin_provision     = $quickstack::params::cinder_san_thin_provision,
  $cinder_eqlx_group_name        = $quickstack::params::cinder_eqlx_group_name,
  $cinder_eqlx_pool              = $quickstack::params::cinder_eqlx_pool,
  $cinder_eqlx_use_chap          = $quickstack::params::cinder_eqlx_use_chap,
  $cinder_eqlx_chap_login        = $quickstack::params::cinder_eqlx_chap_login,
  $cinder_eqlx_chap_password     = $quickstack::params::cinder_eqlx_chap_password,
  $cinder_gluster_volume         = $quickstack::params::cinder_gluster_volume,
  $cinder_user_password          = $quickstack::params::cinder_user_password,
  $controller_admin_host         = $quickstack::params::controller_admin_host,
  $controller_priv_host          = $quickstack::params::controller_priv_host,
  $controller_pub_host           = $quickstack::params::controller_pub_host,
  $glance_db_password            = $quickstack::params::glance_db_password,
  $glance_user_password          = $quickstack::params::glance_user_password,
  $heat_auth_encrypt_key,
  $heat_cfn                      = $quickstack::params::heat_cfn,
  $heat_cloudwatch               = $quickstack::params::heat_cloudwatch,
  $heat_db_password              = $quickstack::params::heat_db_password,
  $heat_user_password            = $quickstack::params::heat_user_password,
  $horizon_secret_key            = $quickstack::params::horizon_secret_key,
  $keystone_admin_token          = $quickstack::params::keystone_admin_token,
  $keystone_db_password          = $quickstack::params::keystone_db_password,
  $keystonerc                    = false,  
  $mysql_host                    = $quickstack::params::mysql_host,
  $mysql_root_password           = $quickstack::params::mysql_root_password,
  $nova_db_password              = $quickstack::params::nova_db_password,
  $nova_user_password            = $quickstack::params::nova_user_password,
  $nova_default_floating_pool    = $quickstack::params::nova_default_floating_pool,
  $qpid_host                     = $quickstack::params::qpid_host,
  $qpid_username                 = $quickstack::params::qpid_username,
  $qpid_password                 = $quickstack::params::qpid_password,
  $swift_shared_secret           = $quickstack::params::swift_shared_secret,
  $swift_admin_password          = $quickstack::params::swift_admin_password,
  $swift_ringserver_ip           = "192.168.203.1",
  $swift_storage_ips             = ["192.168.203.2","192.168.203.3","192.168.203.4"],
  $swift_storage_device          = 'device1',
  $verbose                       = $quickstack::params::verbose,
  $ssl                           = $quickstack::params::ssl,
  $freeipa                       = $quickstack::params::freeipa,
  $mysql_ca                      = $quickstack::params::mysql_ca,
  $mysql_cert                    = $quickstack::params::mysql_cert,
  $mysql_key                     = $quickstack::params::mysql_key,
  $qpid_ca                       = $quickstack::params::qpid_ca,
  $qpid_cert                     = $quickstack::params::qpid_cert,
  $qpid_key                      = $quickstack::params::qpid_key,
  $horizon_ca                    = $quickstack::params::horizon_ca,
  $horizon_cert                  = $quickstack::params::horizon_cert,
  $horizon_key                   = $quickstack::params::horizon_key,
  $qpid_nssdb_password           = $quickstack::params::qpid_nssdb_password,

  $auto_assign_floating_ip
) inherits quickstack::params {
  nova_config {
    'DEFAULT/auto_assign_floating_ip': value => $auto_assign_floating_ip;
    'DEFAULT/multi_host':              value => 'True';
    'DEFAULT/force_dhcp_release':      value => 'False';
  }


  class { 'quickstack::controller_common':
    admin_email                  => $admin_email,
    admin_password               => $admin_password,
    ceilometer_metering_secret   => $ceilometer_metering_secret,
    ceilometer_user_password     => $ceilometer_user_password,
    cinder_enabled_backends      => $cinder_enabled_backends,
    cinder_backend_gluster       => $cinder_backend_gluster,
    cinder_backend_gluster_name  => $cinder_backend_gluster_name,
    cinder_backend_eqlx         => $cinder_backend_eqlx,
    cinder_backend_eqlx_name    => $cinder_backend_eqlx_name,
    cinder_backend_iscsi         => $cinder_backend_iscsi,
    cinder_backend_iscsi_name    => $cinder_backend_iscsi_name,
    cinder_db_password           => $cinder_db_password,
    cinder_gluster_servers       => $cinder_gluster_servers,
    cinder_san_ip               => $cinder_san_ip,
    cinder_san_login            => $cinder_san_login,
    cinder_san_password         => $cinder_san_password,
    cinder_san_thin_provision   => $cinder_san_thin_provision,
    cinder_eqlx_group_name      => $cinder_eqlx_group_name,
    cinder_eqlx_pool            => $cinder_eqlx_pool,
    cinder_eqlx_use_chap        => $cinder_eqlx_use_chap,
    cinder_eqlx_chap_login      => $cinder_eqlx_chap_login,
    cinder_eqlx_chap_password   => $cinder_eqlx_chap_password,
    cinder_gluster_volume        => $cinder_gluster_volume,
    cinder_user_password         => $cinder_user_password,
    controller_admin_host        => $controller_admin_host,
    controller_priv_host         => $controller_priv_host,
    controller_pub_host          => $controller_pub_host,
    glance_db_password           => $glance_db_password,
    glance_user_password         => $glance_user_password,
    heat_auth_encrypt_key        => $heat_auth_encrypt_key,
    heat_cfn                     => $heat_cfn,
    heat_cloudwatch              => $heat_cloudwatch,
    heat_db_password             => $heat_db_password,
    heat_user_password           => $heat_user_password,
    horizon_secret_key           => $horizon_secret_key,
    keystone_admin_token         => $keystone_admin_token,
    keystone_db_password         => $keystone_db_password,
    keystonerc                   => $keystonerc,
    mysql_host                   => $mysql_host,
    mysql_root_password          => $mysql_root_password,
    neutron                      => false,
    nova_db_password             => $nova_db_password,
    nova_user_password           => $nova_user_password,
    nova_default_floating_pool   => $nova_default_floating_pool,
    qpid_host                    => $qpid_host,
    qpid_username                => $qpid_username,
    qpid_password                => $qpid_password,
    swift_shared_secret          => $swift_shared_secret,
    swift_admin_password         => $swift_admin_password,
    swift_ringserver_ip          => $swift_ringserver_ip,
    swift_storage_ips            => $swift_storage_ips,
    swift_storage_device         => $swift_storage_device,
    verbose                      => $verbose,

    ssl                          => $ssl,
    freeipa                      => $freeipa,
    mysql_ca                     => $mysql_ca,
    mysql_cert                   => $mysql_cert,
    mysql_key                    => $mysql_key,
    qpid_ca                      => $qpid_ca,
    qpid_cert                    => $qpid_cert,
    qpid_key                     => $qpid_key,
    horizon_ca                   => $horizon_ca,
    horizon_cert                 => $horizon_cert,
    horizon_key                  => $horizon_key,
    qpid_nssdb_password          => $qpid_nssdb_password,
  }
}
