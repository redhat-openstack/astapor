# Quickstack Service for gluster server
# This could be used when external resources aren't available
# It must be executed on each gluster server in a round robbin mode
class quickstack::gluster::mount (
  $volume_name,
  $volume_path,
  $vip          = $quickstack::params::gluster_vip,
) {

  # mount a share on a client somewhere
  gluster::mount { "${volume_name}":
    server => "${vip}:${volume_path}",
    rw => true,
    mounted => true,
  }
}
