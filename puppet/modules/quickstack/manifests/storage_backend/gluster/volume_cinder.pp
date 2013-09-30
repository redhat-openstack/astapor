# quickstack gluster volume class
class quickstack::storage_backend::gluster::volume_cinder ( 
  $cinder_gluster_path          = $quickstack::params::cinder_gluster_path,
  $cinder_gluster_peers         = $quickstack::params::cinder_gluster_peers,
  $cinder_gluster_replica_count = $quickstack::params::cinder_gluster_replica_count,
) inherits quickstack::params {
  volume { 'cinder':
    ensure         => present,
    path           => $glance_path,
    peers          => $glance_gluster_peers,
    replica_count  => $glance_replica_count, 
  }
}
