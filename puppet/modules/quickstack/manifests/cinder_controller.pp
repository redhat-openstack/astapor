class quickstack::cinder_controller(
  $cinder_db_password,
  $cinder_user_password,
  $controller_priv_floating_ip,
  $mysql_host,
  $qpid_host,
  $verbose,
) {

  cinder_config {
    'DEFAULT/glance_host': value => $controller_priv_floating_ip;
    'DEFAULT/notification_driver': value => 'cinder.openstack.common.notifier.rpc_notifier'
  }

  class {'cinder':
    rpc_backend    => 'cinder.openstack.common.rpc.impl_qpid',
    qpid_hostname  => $qpid_host,
    qpid_password  => 'guest',
    sql_connection => "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder",
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
