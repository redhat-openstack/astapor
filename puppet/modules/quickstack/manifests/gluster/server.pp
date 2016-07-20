# Quickstack Service for gluster server
# This could be used when external resources aren't available
# It must be executed on each gluster server in a round robbin mode
class quickstack::gluster::server (
  $device1       = $quickstack::params::gluster_device1,
  $device2       = $quickstack::params::gluster_device2,
  $device3       = $quickstack::params::gluster_device3,
  $fqdn1         = $quickstack::params::gluster_fqdn1,
  $fqdn2         = $quickstack::params::gluster_fqdn2,
  $fqdn3         = $quickstack::params::gluster_fqdn3,
  $port_count    = $quickstack::params::gluster_port_count,
  $replica_count = $quickstack::params::gluster_replica_count,
  $uuid1         = $quickstack::params::gluster_uuid1,
  $uuid2         = $quickstack::params::gluster_uuid2,
  $uuid3         = $quickstack::params::gluster_uuid3,

  $volume1_gid   = $quickstack::params::gluster_volume1_gid,
  $volume1_name  = $quickstack::params::gluster_volume1_name,
  $volume1_path  = $quickstack::params::gluster_volume1_path,
  $volume1_uid   = $quickstack::params::gluster_volume1_uid,

  $volume2_gid   = $quickstack::params::gluster_volume2_gid,
  $volume2_name  = $quickstack::params::gluster_volume2_name,
  $volume2_path  = $quickstack::params::gluster_volume2_path,
  $volume2_uid   = $quickstack::params::gluster_volume2_uid,

  $volume3_gid   = $quickstack::params::gluster_volume3_gid,
  $volume3_name  = $quickstack::params::gluster_volume3_name,
  $volume3_path  = $quickstack::params::gluster_volume3_path,
  $volume3_uid   = $quickstack::params::gluster_volume3_uid,
) {

  $vip  = ''
  $vrrp =  false

  class {'::gluster::server':
    vip       => $vip,
    vrrp      => $vrrp,
    repo      => false,
    shorewall => false,
  }

  gluster::host {"${fqdn1}":
    uuid => "${uuid1}"
  }

  gluster::host {"${fqdn2}":
    uuid => "${uuid2}"
  }

  gluster::host {"${fqdn3}":
    uuid => "${uuid3}"
  }

  gluster::gluster_brick {"${fqdn1}:${volume1_path}":
    dev => "${device1}",
  }

  gluster::gluster_brick {"${fqdn1}:${volume2_path}":
    dev => "${device2}",
  }

  gluster::gluster_brick {"${fqdn1}:${volume3_path}":
    dev => "${device3}",
  }

  gluster::gluster_brick {"${fqdn2}:${volume1_path}":
    dev => "${device1}",
  }

  gluster::gluster_brick {"${fqdn2}:${volume2_path}":
    dev => "${device2}",
  }

  gluster::gluster_brick {"${fqdn2}:${volume3_path}":
    dev => "${device3}",
  }

  gluster::gluster_brick {"${fqdn3}:${volume1_path}":
    dev => "${device1}",
  }

  gluster::gluster_brick {"${fqdn3}:${volume2_path}":
    dev => "${device2}",
  }

  gluster::gluster_brick {"${fqdn3}:${volume3_path}":
    dev => "${device3}",
  }

  $brick_list = [
    "${fqdn1}:${volume1_path}",
    "${fqdn2}:${volume1_path}",
    "${fqdn3}:${volume1_path}",
    "${fqdn1}:${volume2_path}",
    "${fqdn2}:${volume2_path}",
    "${fqdn3}:${volume2_path}",
    "${fqdn1}:${volume3_path}",
    "${fqdn2}:${volume3_path}",
    "${fqdn3}:${volume3_path}",
  ]

  gluster::volume { ["${volume1_name}", "${volume2_name}", "${volume3_name}"]:
    replica => "${replica_count}",
    bricks  => $brick_list,
    vip     => "${vip}",
    ping    => false,  # disable fping
    start   => true,
    again   => false,
  }

  gluster::volume::property {"${volume1_name}#storage.owner-uid":
    value => $volume1_uid,
  }

  gluster::volume::property {"${volume1_name}#storage.owner-gid":
    value => $volume1_gid,
  }

  gluster::volume::property {"${volume2_name}#storage.owner-uid":
    value => $volume2_uid,
  }

  gluster::volume::property {"${volume2_name}#storage.owner-gid":
    value => $volume2_gid,
  }

  gluster::volume::property {"${volume3_name}#storage.owner-uid":
    value => $volume3_uid,
  }

  gluster::volume::property {"${volume3_name}#storage.owner-gid":
    value => $volume3_gid,
  }

  gluster::volume::property::group {"${volume1_name}#virt":}

  gluster::volume::property::group {"${volume2_name}#virt":}

  gluster::volume::property::group {"${volume3_name}#virt":}

  class {'quickstack::firewall::gluster':
    port_count => "${port_count}",
  }
}
