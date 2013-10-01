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

  if $cinder_backend_gluster == true {
    class { 'gluster::client': }

    class { 'cinder::volume::glusterfs':
      glusterfs_shares => split(join($cinder_gluster_peers, $cinder_path + ','), ',')
    }

    firewall { '001 gluster bricks incoming':
      proto  => 'tcp',
      # dport  => port_range('24009', size($cinder_gluster_peers))
      dport  => [ '24009', '24010', '24011' ],
      action => 'accept',
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
