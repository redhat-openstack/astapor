# Parameters for the volumes to be managed by gluster
class quickstack::storage_backend::gluster::params {
  $cinder_path          => '/srv/gluster/cinder'
  $cinder_gluster_peers => [ '192.168.0.2', '192.168.0.3', '192.168.0.4' ]
  $cinder_replica_count => '3'

  $glance_path          => '/srv/gluster/glance'
  $glance_gluster_peers => [ '192.168.0.2', '192.168.0.3', '192.168.0.4' ]
  $glance_replica_count => '3'

  $swift_path          => '/srv/gluster/swift'
  $swift_gluster_peers => [ '192.168.0.2', '192.168.0.3', '192.168.0.4' ]
  $swift_replica_count => '3'
}
