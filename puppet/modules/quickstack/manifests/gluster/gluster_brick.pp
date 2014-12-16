define gluster::gluster_brick (
  name,
  dev,
) {
  gluster::brick {"${name}":
    dev         => "${dev}",
    raid_su     => '256',
    raid_sw     => '10',
    partition   => true,
    lvm         => true,
    fstype      => 'xfs',
    xfs_inode64 => true,
    #xfs_nobarrier => true,
    force       => true,
    areyousure  => true,
    again       => false,
  }
}
