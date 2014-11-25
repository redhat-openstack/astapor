class quickstack::roles::ceph::fsid (
) {

  include ::quickstack::ceph::client_packages

    class { '::quickstack::ceph::config':
      fsid                => $ceph_fsid,
      cluster_network     => $ceph_cluster_network,
      public_network      => $ceph_public_network,
      mon_initial_members => $ceph_mon_initial_members,
      mon_host            => $ceph_mon_host,
      images_key          => $ceph_images_key,
      volumes_key         => $ceph_volumes_key,
    } -> Class['quickstack::ceph::client_packages']
  }

  package {'python-ceph': } ->
  Class['quickstack::ceph::client_packages'] -> Package['nova-compute']
}
