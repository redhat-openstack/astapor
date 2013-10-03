# Cinder Storage
class quickstack::cinder_storage (
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_iscsi        = $quickstack::params::cinder_backend_iscsi,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $cinder_gluster_volume       = $quickstack::params::cinder_gluster_volume,
  $cinder_gluster_peers        = $quickstack::params::cinder_gluster_peers,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $private_interface           = $quickstack::params::private_interface,
) inherits quickstack::params {
  class { 'cinder::volume': }

  if $cinder_backend_gluster == true {
    class { 'gluster::client': }

    class { 'cinder::volume::glusterfs':
      glusterfs_mount_point_base => '/var/lib/cinder/volumes',
      glusterfs_shares           => suffix($cinder_gluster_peers, ":/${cinder_gluster_volume}")
    }

    firewall { '001 gluster bricks incoming':
      proto  => 'tcp',
      # dport  => port_range('24009', size($cinder_gluster_peers)),
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
