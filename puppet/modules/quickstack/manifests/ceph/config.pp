# Class quickstack::ceph::config
#
# Parameters:
#   [*fsid*]                  - fsid in /etc/ceph/ceph.conf, e.g. a uuid from uuidgen
#   [*mon_initial_members*]   - mon_initial_members in /etc/ceph/ceph.conf (array of short hostnames)
#   [*mon_host*]              - mon_host in /etc/ceph/ceph.conf (array of IP's)
#   [*cluster_network*]       - subnet, e.g. 10.0.0.0/24
#   [*public_network*]        - subnet, e.g. 10.0.1.0/24
#   [*images_key*]            - key in /etc/ceph/ceph.client.images.keyring
#   [*volumes_key*]           - key in /etc/ceph/ceph.client.volumes.keyring
#   [*osd_pool_default_size*] - osd_pool_default_size in in /etc/ceph/ceph.conf (effects replicas)
#                                leave blank to omit from ceph.conf
#   [*osd_journal_size*]      - osd_journal_size in in /etc/ceph/ceph.conf
#                                leave blank to omit from ceph.conf
#
# Usage:
#
#   class { 'quickstack::ceph::config':
#     fsid                => '67ce55e2-6d6e-411e-aad9-6e258a040da4',
#     mon_initial_members => ['mon1','mon2','mon3'],
#     mon_host            => ['192.168.7.151','192.168.7.152','192.168.7.153' ],
#     images_key          => 'AQBl5NlTKMsvMhAAXxkeO+h4fN3GH59GAAkfcw==',
#     volumes_key         => 'AQBm5NlT6ANrAxAACMAgoMMTPN5qiRCtqqNBCw==',
#   }



class quickstack::ceph::config (
  $manage_ceph_conf        = true,
  $fsid                    = '',
  $mon_initial_members     = [ ],
  $mon_host                = [ ],
  $cluster_network         = '',
  $public_network          = '',
  $images_key              = '',
  $volumes_key             = '',
  $rgw_key                 = '',
  $conf_include_osd_global = true,
  $osd_pool_default_size   = '',
  $osd_journal_size        = '',
  $osd_mkfs_options_xfs    = '-f -i size=2048 -n size=64k',
  $osd_mount_options_xfs   = 'inode64,noatime,logbsize=256k',
  $conf_include_rgw        = false,
  $rgw_hostnames           = [ ],
  $extra_conf_lines        = [ ],
) {

  if $rgw_hostnames == [ ] {
    $_rgw_hostnames = [$::hostname]
  } else {
    $_rgw_hostnames = $rgw_hostnames
  }

  file { 'etc-ceph':
    ensure => directory,
    path   => '/etc/ceph',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if str2bool_i("$manage_ceph_conf") {
    File['etc-ceph'] ->
    file { 'etc-ceph-conf':
      path    => '/etc/ceph/ceph.conf',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('quickstack/ceph-conf.erb'),
    }
  }

  if $conf_include_rgw {
    file { 'var-lib-ceph':
      ensure => directory,
      path   => '/var/lib/ceph',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    } ->
    file { 'var-lib-ceph-radosgw':
      ensure => directory,
      path   => '/var/lib/ceph/radosgw',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    } ->
    file { 'var-lib-ceph-radosgw-ceph-radosgw.gateway':
      ensure => directory,
      path   => '/var/lib/ceph/radosgw/ceph-radosgw.gateway',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }

  if $images_key {
    File['etc-ceph'] ->
    ::quickstack::ceph::keyring_config{ 'images':
      key => $images_key,
    }
  }
  if $volumes_key {
    File['etc-ceph'] ->
    ::quickstack::ceph::keyring_config{ 'volumes':
      key => $volumes_key,
      caps_osd => 'allow class-read object_prefix rbd_children, allow rx pool=images, allow rwx pool=volumes',
    }
  }
  if $rgw_key {
    File['etc-ceph'] ->
    ::quickstack::ceph::keyring_config{ "rados.gateway":
      key              => $rgw_key,
      caps_mon         => 'allow rwx',
      caps_osd         => 'allow rwx',
      keyring_filename => '/etc/ceph/ceph.client.radosgw.keyring',
    }
  }
}
