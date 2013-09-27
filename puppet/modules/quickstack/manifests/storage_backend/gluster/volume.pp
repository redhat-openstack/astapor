# quickstack gluster volume class
class quickstack::storage_backend::gluster::volume ( 
  $cinder_path          = $quickstack::storage_backend::gluster::params::cinder_path,
  $cinder_gluster_peers = $quickstack::storage_backend::gluster::params::cinder_gluster_peers,
  $cinder_replica_count = $quickstack::storage_backend::gluster::params::cinder_replica_count,
  $glance_path          = $quickstack::storage_backend::gluster::params::glance_path,
  $glance_gluster_peers = $quickstack::storage_backend::gluster::params::glance_gluster_peers,
  $glance_replica_count = $quickstack::storage_backend::gluster::params::glance_replica_count,
  $swift_path           = $quickstack::storage_backend::gluster::params::swift_path,
  $swift_gluster_peers  = $quickstack::storage_backend::gluster::params::swift_gluster_peers,
  $swift_replica_count  = $quickstack::storage_backend::gluster::params::swift_replica_count,
) inherits quickstack::storage_backend::gluster::params {
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