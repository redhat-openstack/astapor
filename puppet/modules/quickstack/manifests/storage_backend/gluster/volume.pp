# quickstack gluster volume class
class quickstack::storage_backend::gluster::volume ( 
  $cinder_path          = $quickstack::params::cinder_path,
  $cinder_gluster_peers = $quickstack::params::cinder_gluster_peers,
  $cinder_replica_count = $quickstack::params::cinder_replica_count,
  $glance_path          = $quickstack::params::glance_path,
  $glance_gluster_peers = $quickstack::params::glance_gluster_peers,
  $glance_replica_count = $quickstack::params::glance_replica_count,
  $swift_path           = $quickstack::params::swift_path,
  $swift_gluster_peers  = $quickstack::params::swift_gluster_peers,
  $swift_replica_count  = $quickstack::params::swift_replica_count,
) inherits quickstack::params {
  volume { 'glance':
    ensure         => present,
    path           => $cinder_path,
    peers          => $cinder_gluster_peers,
    replica_count  => $cinder_replica_count, 
  }

  volume { 'cinder':
    ensure         => present,
    path           => $glance_path,
    peers          => $glance_gluster_peers,
    replica_count  => $glance_replica_count, 
  }

  volume { 'swift':
    ensure         => present,
    path           => $swift_path,
    peers          => $swift_gluster_peers,
    replica_count  => $swift_replica_count, 
  }
}