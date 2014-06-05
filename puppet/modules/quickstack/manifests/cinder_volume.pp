class quickstack::cinder_volume(
  $volume_backend,
  $iscsi_bind_addr   = '',
  $glusterfs_shares  = [],
  $nfs_shares        = [],
  $nfs_mount_options = undef,
) {
  class { '::cinder::volume': }

  if $volume_backend == 'glusterfs' {
    if defined('gluster::client') {
      class { 'gluster::client': }
      ->
      Class['::cinder::volume']
    } else {
      class { 'puppet::vardir': }
      ->
      class { 'gluster::mount::base': repo => false }
      ->
      Class['::cinder::volume']
    }

    if ($::selinux != "false") {
      selboolean {'virt_use_fusefs':
          value => on,
          persistent => true,
      }
    }

    class { '::cinder::volume::glusterfs':
      glusterfs_mount_point_base => '/var/lib/cinder/volumes',
      glusterfs_shares => $glusterfs_shares,
    }
  } elsif $volume_backend == 'nfs' {
    if ($::selinux != "false") {
      selboolean {'virt_use_nfs':
          value => on,
          persistent => true,
      }
    }

    class { '::cinder::volume::nfs':
      nfs_servers       => $nfs_shares,
      nfs_mount_options => $nfs_mount_options,
    }
  } elsif $volume_backend == 'iscsi' {
    include ::quickstack::firewall::iscsi

    class { '::cinder::volume::iscsi':
      iscsi_ip_address => $iscsi_bind_addr,
    }
  } else {
      fail("Unsupported cinder volume backend '${volume_backend}'")
  }
}
