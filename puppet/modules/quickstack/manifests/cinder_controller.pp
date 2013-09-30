class quickstack::cinder_controller(
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $cinder_user_password        = $quickstack::params::cinder_user_password,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {
  cinder_config {
    'DEFAULT/glance_host': value => $controller_priv_floating_ip;
    'DEFAULT/notification_driver': value => 'cinder.openstack.common.notifier.rpc_notifier'
  }
    
  class {'cinder':
    rpc_backend    => 'cinder.openstack.common.rpc.impl_qpid',
    qpid_hostname  => $controller_priv_floating_ip,
    qpid_password  => 'guest',
    sql_connection => "mysql://cinder:${cinder_db_password}@${controller_priv_floating_ip}/cinder",
    verbose        => $verbose,
    require        => Class['openstack::db::mysql', 'qpid::server'],
  }

  class {'cinder::api':
    keystone_password => $cinder_user_password,
    keystone_tenant => "services",
    keystone_user => "cinder",
    keystone_auth_host => $controller_priv_floating_ip,
  }

  class {'cinder::scheduler': }
}
