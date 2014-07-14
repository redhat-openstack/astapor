# Quickstack Service for gluster server
# This could be used when external resources aren't available
# It must be executed on each gluster server in a round robbin mode
class quickstack::gluster::server (
  $cinder_device  = $quickstack::params::cinder_gluster_device,
  $cinder_path    = $quickstack::params::cinder_gluster_path,
  $cinder_peers   = $quickstack::params::cinder_gluster_peers,
  $cinder_replica = $quickstack::params::cinder_gluster_replica_count,
  $cinder_volume  = $quickstack::params::cinder_gluster_volume,
  $glance_device  = $quickstack::params::glance_gluster_device,
  $glance_path    = $quickstack::params::glance_gluster_path,
  $glance_peers   = $quickstack::params::glance_gluster_peers,
  $glance_replica = $quickstack::params::glance_gluster_replica_count,
  $glance_volume  = $quickstack::params::glance_gluster_volume,
  $swift_device   = $quickstack::params::swift_gluster_device,
  $swift_path     = $quickstack::params::swift_gluster_path,
  $swift_peers    = $quickstack::params::swift_gluster_peers,
  $swift_replica  = $quickstack::params::swift_gluster_replica_count,
  $swift_volume   = $quickstack::params::swift_gluster_volume,
  # Firewall
  $port_count    = $quickstack::params::gluster_open_port_count,
) {

  quickstack::gluster::server::volume {'cinder':
    device      => $cinder_device,
    peers       => $cinder_peers,
    replica     => $cinder_replica,
    volume_gid  => '165',
    volume_name => $cinder_volume,
    volume_path => $cinder_path,
    volume_uid  => '165',
  }

  quickstack::gluster::server::volume {'glance':
    device      => $glance_device,
    peers       => $glance_peers,
    replica     => $glance_replica,
    volume_gid  => '161',
    volume_name => $glance_volume,
    volume_path => $glance_path,
    volume_uid  => '161',
  }

  quickstack::gluster::server::volume {'swift':
    device      => $swift_device,
    peers       => $swift_peers,
    replica     => $swift_replica,
    volume_gid  => '160',
    volume_name => $swift_volume,
    volume_path => $swift_path,
    volume_uid  => '160',
  }

  class {'quickstack::firewall::gluster':
    port_count => "${port_count}",
  }
}
