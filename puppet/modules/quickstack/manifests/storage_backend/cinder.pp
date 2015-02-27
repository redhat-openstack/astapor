class quickstack::storage_backend::cinder(
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_gluster_name = $quickstack::params::cinder_backend_gluster_name,
  $cinder_backend_iscsi        = $quickstack::params::cinder_backend_iscsi,
  $cinder_backend_iscsi_name   = $quickstack::params::cinder_backend_iscsi_name,
  $cinder_backend_nfs          = $quickstack::params::cinder_backend_nfs,
  $cinder_backend_nfs_name     = $quickstack::params::cinder_backend_nfs_name,
  $cinder_backend_netapp       = $quickstack::params::cinder_backend_netapp,
  $cinder_backend_netapp_name  = $quickstack::params::cinder_backend_netapp_name,
  $cinder_backend_rbd          = $quickstack::params::cinder_backend_rbd,
  $cinder_backend_rbd_name     = $quickstack::params::cinder_backend_rbd_name,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $cinder_multiple_backends    = $quickstack::params::cinder_multiple_backends,
  $cinder_gluster_shares       = $quickstack::params::cinder_gluster_shares,
  $cinder_nfs_shares           = $quickstack::params::cinder_nfs_shares,
  $cinder_nfs_mount_options    = $quickstack::params::cinder_nfs_mount_options,
  $cinder_rbd_pool             = $quickstack::params::cinder_rbd_pool,
  $cinder_rbd_ceph_conf        = $quickstack::params::cinder_rbd_ceph_conf,
  $cinder_rbd_flatten_volume_from_snapshot
                               = $quickstack::params::cinder_rbd_flatten_volume_from_snapshot,
  $cinder_rbd_max_clone_depth  = $quickstack::params::cinder_rbd_max_clone_depth,
  $cinder_rbd_user             = $quickstack::params::cinder_rbd_user,
  $cinder_rbd_secret_uuid      = $quickstack::params::cinder_rbd_secret_uuid,
  $cinder_user_password        = $quickstack::params::cinder_user_password,
  $controller_priv_host        = $quickstack::params::controller_priv_host,
  $cinder_iscsi_iface          = 'eth1',
  $cinder_iscsi_network        = '',
  $mysql_host                  = $quickstack::params::mysql_host,
  $amqp_provider               = $quickstack::params::amqp_provider,
  $amqp_host                   = $quickstack::params::amqp_host,
  $amqp_username               = $quickstack::params::amqp_username,
  $amqp_password               = $quickstack::params::amqp_password,
  $verbose                     = $quickstack::params::verbose,
  $ssl                         = $quickstack::params::ssl,
  $mysql_ca                    = $quickstack::params::mysql_ca,
) inherits quickstack::params {

  class {'quickstack::openstack_common': }

  if str2bool_i("$ssl") {
    $qpid_protocol = 'ssl'
    $amqp_port = '5671'
    $sql_connection = "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder?ssl_ca=${mysql_ca}"
  } else {
    $qpid_protocol = 'tcp'
    $amqp_port = '5672'
    $sql_connection = "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder"
  }
  class { '::cinder':
    rpc_backend    => amqp_backend('cinder', $amqp_provider),
    qpid_hostname  => $amqp_host,
    qpid_port      => $amqp_port,
    qpid_protocol  => $qpid_protocol,
    qpid_username  => $amqp_username,
    qpid_password  => $amqp_password,
    rabbit_host    => $amqp_host,
    rabbit_port    => $amqp_port,
    rabbit_userid  => $amqp_username,
    rabbit_password=> $amqp_password,
    sql_connection => $sql_connection,
    verbose        => $verbose,
  }

  $iscsi_ip_address = find_ip("$cinder_iscsi_network",
                              "$cinder_iscsi_iface",
                              "")

  class { 'quickstack::cinder_volume':
    backend_glusterfs      => $cinder_backend_gluster,
    backend_glusterfs_name => $cinder_backend_gluster_name,
    backend_iscsi          => $cinder_backend_iscsi,
    backend_iscsi_name     => $cinder_backend_iscsi_name,
    backend_nfs            => $cinder_backend_nfs,
    backend_nfs_name       => $cinder_backend_nfs_name,
    backend_netapp         => $cinder_backend_netapp,
    backend_netapp_name    => $cinder_backend_netapp_name,
    backend_rbd            => $cinder_backend_rbd,
    backend_rbd_name       => $cinder_backend_rbd_name,
    multiple_backends      => $cinder_multiple_backends,
    iscsi_bind_addr        => $iscsi_ip_address,
    glusterfs_shares       => $cinder_gluster_shares,
    nfs_shares             => $cinder_nfs_shares,
    nfs_mount_options      => $cinder_nfs_mount_options,
    rbd_pool               => $cinder_rbd_pool,
    rbd_ceph_conf          => $cinder_rbd_ceph_conf,
    rbd_flatten_volume_from_snapshot
                           => $cinder_rbd_flatten_volume_from_snapshot,
    rbd_max_clone_depth    => $cinder_rbd_max_clone_depth,
    rbd_user               => $cinder_rbd_user,
    rbd_secret_uuid        => $cinder_rbd_secret_uuid,
  }
}
