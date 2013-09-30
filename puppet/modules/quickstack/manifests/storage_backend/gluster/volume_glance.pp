# quickstack gluster volume class
class quickstack::storage_backend::gluster::volume_glance (
  $glance_gluster_path          = $quickstack::params::glance_gluster_path,
  $glance_gluster_peers         = $quickstack::params::glance_gluster_peers,
  $glance_gluster_replica_count = $quickstack::params::glance_gluster_replica_count,
) inherits quickstack::params {
  volume { 'glance':
    ensure         => present,
    path           => $cinder_path,
    peers          => $cinder_gluster_peers,
    replica_count  => $cinder_replica_count, 
  }
}
