class quickstack::cinder_controller(
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_iscsi        = $quickstack::params::cinder_backend_iscsi,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $cinder_gluster_volume       = $quickstack::params::cinder_gluster_volume,
  $cinder_gluster_peers        = $quickstack::params::cinder_gluster_peers,
  $cinder_user_password        = $quickstack::params::cinder_user_password,
  $controller_priv_host        = $quickstack::params::controller_priv_host,
  $mysql_host                  = $quickstack::params::mysql_host,
  $mysql_ca                    = $quickstack::params::mysql_ca,
  $ssl                         = $quickstack::params::ssl,
  $qpid_host                   = $quickstack::params::qpid_host,
  $qpid_port                   = "5672",
  $qpid_protocol               = "tcp",
  $qpid_username               = $quickstack::params::qpid_username,
  $qpid_password               = $quickstack::params::qpid_password,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {

  $qpid_password_safe_for_cinder = $qpid_password ? {
    ''      => 'guest',
    false   => 'guest',
    default => $qpid_password,
  }

  cinder_config {
    'DEFAULT/glance_host': value => $controller_priv_host;
    'DEFAULT/notification_driver': value => 'cinder.openstack.common.notifier.rpc_notifier'
  }

  if str2bool_i("$ssl") {
    $sql_connection = "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder?ssl_ca=${mysql_ca}"
  } else {
    $sql_connection = "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder"
  }

  class {'::cinder':
    rpc_backend    => 'cinder.openstack.common.rpc.impl_qpid',
    qpid_hostname  => $qpid_host,
    qpid_protocol  => $qpid_protocol,
    qpid_port      => $qpid_port,
    qpid_username  => $qpid_username,
    qpid_password  => $qpid_password_safe_for_cinder,
    sql_connection => $sql_connection,
    verbose        => $verbose,
    require        => Class['quickstack::db::mysql', 'qpid::server'],
  }

  class {'::cinder::api':
    keystone_password => $cinder_user_password,
    keystone_tenant => "services",
    keystone_user => "cinder",
    keystone_auth_host => $controller_priv_host,
  }

  class {'::cinder::scheduler': }

  if str2bool_i("$cinder_backend_gluster") {
    class { '::cinder::volume': }

    class { 'gluster::client': }

    if ($::selinux != "false") {
      selboolean{'virt_use_fusefs':
        value => on,
        persistent => true,
      }
    }

    class { '::cinder::volume::glusterfs':
      glusterfs_mount_point_base => '/var/lib/cinder/volumes',
      glusterfs_shares           => suffix($cinder_gluster_peers, ":/${cinder_gluster_volume}")
    }
  }

  if !str2bool_i("$cinder_backend_gluster") and !str2bool_i("$cinder_backend_iscsi") {
    class { '::cinder::volume': }

    class { '::cinder::volume::iscsi':
      iscsi_ip_address => $controller_priv_host,
    }

    firewall { '010 cinder iscsi':
      proto  => 'tcp',
      dport  => ['3260'],
      action => 'accept',
    }
  }
}
