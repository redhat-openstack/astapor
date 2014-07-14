# Quickstack Service for gluster server
# This could be used when external resources aren't available
# It must be executed on each gluster server in a round robbin mode
define quickstack::gluster::server::volume (
  $device,
  $peers,
  $replica,
  $volume_gid,
  $volume_name,
  $volume_path,
  $volume_uid,
) {

  $bricks = []
  $vip    = ''
  $vrrp   =  false

  class {'::gluster::server':
    vip       => $vip,
    vrrp      => $vrrp,
    repo      => false,
    shorewall => false,
  }

  $peers.each |$fqdn, $uuid| {
    gluster::host {$fqdn:
      uuid => $uuid
    }

    gluster::brick {"${fqdn}:${volume_path}":
      dev         => $device,
      raid_su     => '256',
      raid_sw     => '10',
      partition   => true,
      lvm         => true,
      fstype      => 'xfs',
      xfs_inode64 => true,
      #xfs_nobarrier => true,
      force       => true,
      areyousure  => true,
    }

    $bricks = concat($bricks, ["${fqdn}:${volume_path}"])
  }

  gluster::volume {$volume_name:
    replica => $replica,
    bricks  => $bricks,
    vip     => $vip,
    ping    => false,  # disable fping
    start   => true,
  }

  gluster::volume::property {"${volume_name}#storage.owner-uid":
    value => $volume_uid,
  }

  gluster::volume::property {"${volume_name}#storage.owner-gid":
    value => $volume_gid,
  }

  gluster::volume::property::group {"${volume_name}#virt":}
}
