class glance::volume::glusterfs (
  $glusterfs_shares,
  $glusterfs_disk_util = undef,
  $glusterfs_sparsed_volumes = undef,
  $glusterfs_mount_point_base = '/var/lib/glance/images/',
  $glusterfs_shares_config = '/etc/glance/shares.conf'
) {

  $content = join($glusterfs_shares, "\n")

  file {$glusterfs_shares_config:
    content => "${content}\n",
    require => Package['glance'],
    notify => Service['glance-volume']
  }

  glance_config {
    'DEFAULT/filesystem_store_datadir': value => $glusterfs_mount_point_base;
  }
}