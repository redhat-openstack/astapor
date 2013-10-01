# Cinder Storage
class quickstack::cinder_storage (
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_iscsi        = $quickstack::params::cinder_backend_iscsi,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $cinder_gluster_path         = $quickstack::params::cinder_gluster_path,
  $cinder_gluster_peers        = $quickstack::params::cinder_gluster_peers,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $private_interface           = $quickstack::params::private_interface,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {
  class { 'cinder':
    rpc_backend    => 'cinder.openstack.common.rpc.impl_qpid',
    qpid_hostname  => $controller_priv_floating_ip,
    qpid_password  => 'guest',
    sql_connection => "mysql://cinder:${cinder_db_password}@${controller_priv_floating_ip}/cinder",
    verbose        => $verbose,
  }

  class { 'cinder::volume': }

}
