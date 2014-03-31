class quickstack::firewall::gluster (
  $port_rpc      = [ '111' ],
  $port_glusterd = [ '24007', '24008' ],
  $port_glusterb = '49152',
  $port_count
) {

  include quickstack::firewall::common

  firewall {'001 RPC TCP daemon incoming':
    proto  => 'tcp',
    dport  => $port_rpc,
    action => 'accept',
  }

  firewall {'001 RPC UDP daemon incoming':
    proto  => 'udp',
    dport  => $port_rpc,
    action => 'accept',
  }

  firewall {'001 Glusterfs TCP daemon incoming':
    proto  => 'tcp',
    dport  => $port_glusterd,
    action => 'accept',
  }

  # One port per brick
  firewall {'001 Glusterfs bricks TCP incoming':
    proto  => 'tcp',
    dport  => port_range($port_glusterb, $port_count),
    action => 'accept',
  }
}
