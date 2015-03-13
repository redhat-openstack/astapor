class quickstack::pacemaker::ceph_config {

  include quickstack::pacemaker::common

  class { '::quickstack::ceph::config':
    manage_ceph_conf        => map_params('manage_ceph_conf'),
    fsid                    => map_params('ceph_fsid'),
    cluster_network         => map_params('ceph_cluster_network'),
    public_network          => map_params('ceph_public_network'),
    mon_initial_members     => map_params('ceph_mon_initial_members'),
    mon_host                => map_params('ceph_mon_host'),
    images_key              => map_params('ceph_images_key'),
    volumes_key             => map_params('ceph_volumes_key'),
    rgw_key                 => map_params('ceph_rgw_key'),
    conf_include_osd_global => map_params('ceph_conf_include_osd_global'),
    osd_pool_default_size   => map_params('ceph_osd_pool_size'),
    osd_journal_size        => map_params('ceph_osd_journal_size'),
    osd_mkfs_options_xfs    => map_params('ceph_osd_mkfs_options_xfs'),
    osd_mount_options_xfs   => map_params('ceph_osd_mount_options_xfs'),
    conf_include_rgw        => map_params('ceph_conf_include_rgw'),
    rgw_hostnames           => map_params('ceph_rgw_hostnames'),
    extra_conf_lines        => map_params('ceph_extra_conf_lines'),
  }
}
