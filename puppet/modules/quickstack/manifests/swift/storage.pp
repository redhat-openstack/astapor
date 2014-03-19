class quickstack::swift::storage (
  # an array, the storage nodes and proxy node(s)
  $swift_all_ips                  = ['192.168.203.1', '192.168.203.2', '192.168.203.3', '192.168.203.4'],
  $swift_ext4_device              = '/dev/sdc2',
  $swift_local_interface          = 'eth3',
  $swift_loopback                 = true,
  $swift_ring_server              = '192.168.203.1',  # an ip addr
  $swift_shared_secret            = '',
) inherits quickstack::params {

  class { '::swift::storage::all':
    storage_local_net_ip => getvar(regsubst("ipaddress_${swift_local_interface}", '[.-]', '_', 'G')),
    require => Class['swift'],
    log_facility => 'LOG_LOCAL1',
  }

  if(!defined(File['/srv/node'])) {
    file { '/srv/node':
      owner  => 'swift',
      group  => 'swift',
      ensure => directory,
      require => Package['openstack-swift'],
    }
  }

  swift::ringsync{["account","container","object"]:
      ring_server => $swift_ring_server,
      before => Class['swift::storage::all'],
      require => Class['swift'],
  }

  File <| |> -> Exec['restorcon']
  exec{'restorcon':
      path => '/sbin:/usr/sbin',
      command => 'restorecon -RvF /srv',
  }

  if ($::selinux != "false"){
      selboolean{'rsync_client':
          value => on,
          persistent => true,
      }
  }

  if str2bool_i("$swift_loopback") {
    swift::storage::loopback { ['device1']:
      base_dir     => '/srv/loopback-device',
      mnt_base_dir => '/srv/node',
      require      => Class['swift'],
      fstype       => 'ext4',
      seek         => '1048576',
    }
  } else {
    swift::storage::ext4 { "device1":
      device => $swift_ext4_device,
    }
  }

  # Create firewall rules to allow only the hosts that need to connect
  # to swift storage and rsync
  define add_allow_host_swift {
      firewall { "001 swift storage and rsync incoming ${title}":
          proto  => 'tcp',
          dport  => ['6000', '6001', '6002', '873'],
          action => 'accept',
          source => $title,
      }
  }
  add_allow_host_swift {$all_swift_ips:}

  class { 'ssh::server::install': }

  Class['swift'] -> Service <| |>
  class { 'swift':
      # not sure how I want to deal with this shared secret
      swift_hash_suffix => $swift_shared_secret,
      package_ensure    => latest,
  }

}
