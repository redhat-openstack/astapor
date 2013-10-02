# quickstack gluster volume class
class quickstack::storage_backend::gluster::volume_swift (
  $swift_gluster_path          = $quickstack::params::swift_gluster_path,
  $swift_gluster_peers         = $quickstack::params::swift_gluster_peers,
  $swift_gluster_replica_count = $quickstack::params::swift_gluster_replica_count,
) inherits quickstack::params {
  volume { 'swift':
    ensure         => present,
    path           => $swift_gluster_path,
    peers          => $swift_gluster_peers,
    replica_count  => $swift_replica_count, 
  }
}
