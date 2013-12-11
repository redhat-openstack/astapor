# Quickstart class for nova network controller
class quickstack::nova_network::controller (
  $admin_email                   = $quickstack::params::admin_email,
  $admin_password                = $quickstack::params::admin_password,
  $ceilometer_metering_secret    = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password      = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster        = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_iscsi          = $quickstack::params::cinder_backend_iscsi,
  $cinder_db_password            = $quickstack::params::cinder_db_password,
  $cinder_gluster_peers          = $quickstack::params::cinder_gluster_peers,
  $cinder_gluster_volume         = $quickstack::params::cinder_gluster_volume,
  $cinder_user_password          = $quickstack::params::cinder_user_password,
  $controller_priv_floating_ip   = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip    = $quickstack::params::controller_pub_floating_ip,
  $glance_db_password            = $quickstack::params::glance_db_password,
  $glance_user_password          = $quickstack::params::glance_user_password,
  $heat_cfn                      = $quickstack::params::heat_cfn,
  $heat_cloudwatch               = $quickstack::params::heat_cloudwatch,
  $heat_db_password              = $quickstack::params::heat_db_password,
  $heat_user_password            = $quickstack::params::heat_user_password,
  $horizon_secret_key            = $quickstack::params::horizon_secret_key,
  $keystone_admin_token          = $quickstack::params::keystone_admin_token,
  $keystone_db_password          = $quickstack::params::keystone_db_password,
  $mysql_host                    = $quickstack::params::mysql_host,
  $mysql_root_password           = $quickstack::params::mysql_root_password,
  $nova_db_password              = $quickstack::params::nova_db_password,
  $nova_user_password            = $quickstack::params::nova_user_password,
  $qpid_host                     = $quickstack::params::qpid_host,
  $qpid_username                 = $quickstack::params::qpid_username,
  $qpid_password                 = $quickstack::params::qpid_password,
  $swift_shared_secret           = $quickstack::params::swift_shared_secret,
  $swift_admin_password          = $quickstack::params::swift_admin_password,
  $verbose                       = $quickstack::params::verbose,

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
    cinder_backend_gluster       => $cinder_backend_gluster,
    cinder_backend_iscsi         => $cinder_backend_iscsi,
    cinder_db_password           => $cinder_db_password,
    cinder_gluster_peers         => $cinder_gluster_peers,
    cinder_gluster_volume        => $cinder_gluster_volume,
    cinder_user_password         => $cinder_user_password,
    controller_priv_floating_ip  => $controller_priv_floating_ip,
    controller_pub_floating_ip   => $controller_pub_floating_ip,
    glance_db_password           => $glance_db_password,
    glance_user_password         => $glance_user_password,
    heat_cfn                     => $heat_cfn,
    heat_cloudwatch              => $heat_cloudwatch,
    heat_db_password             => $heat_db_password,
    heat_user_password           => $heat_user_password,
    horizon_secret_key           => $horizon_secret_key,
    keystone_admin_token         => $keystone_admin_token,
    keystone_db_password         => $keystone_db_password,
    mysql_host                   => $mysql_host,
    mysql_root_password          => $mysql_root_password,
    neutron                      => false,
    nova_db_password             => $nova_db_password,
    nova_user_password           => $nova_user_password,
    qpid_host                    => $qpid_host,
    qpid_username                => $qpid_username,
    qpid_password                => $qpid_password,
    swift_shared_secret          => $swift_shared_secret,
    swift_admin_password         => $swift_admin_password,
    verbose                      => $verbose,
  }
}
