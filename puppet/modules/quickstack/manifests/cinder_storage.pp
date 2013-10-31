# Cinder Storage
class quickstack::cinder_storage (
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_iscsi        = $quickstack::params::cinder_backend_iscsi,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $cinder_gluster_volume       = $quickstack::params::cinder_gluster_volume,
  $cinder_gluster_peers        = $quickstack::params::cinder_gluster_peers,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $private_interface           = $quickstack::params::private_interface,
  $mysql_host                  = $quickstack::params::mysql_host,
  $qpid_host                   = $quickstack::params::qpid_host,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {

  class { 'cinder':
    rpc_backend    => 'cinder.openstack.common.rpc.impl_qpid',
    qpid_hostname  => $qpid_host,
    qpid_password  => 'guest',
    sql_connection => "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder",
    verbose        => $verbose,
  }

  class { 'cinder::volume': }

  if $cinder_backend_gluster == true {
    class { 'gluster::client': }

    class { 'cinder::volume::glusterfs':
      glusterfs_mount_point_base => '/var/lib/cinder/volumes',
      glusterfs_shares           => suffix($cinder_gluster_peers, ":/${cinder_gluster_volume}")
    }
  }

  if $cinder_backend_iscsi == true {
    class { 'cinder::volume::iscsi':
      iscsi_ip_address => getvar("ipaddress_${private_interface}"),
    }

    firewall { '010 cinder iscsi':
      proto  => 'tcp',
      dport  => ['3260'],
      action => 'accept',
    }
  }
}
