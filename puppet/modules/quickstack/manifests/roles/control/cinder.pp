#
class quickstack::roles::control::cinder (
  $verbose         = 'false',
) inherits quickstack::roles::params {

  class { 'cinder::keystone::auth':
    password         => $cinder_user_password,
    public_address   => $cinder_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $cinder_vip_admin,
    internal_address => $cinder_vip_internal,
    region           => $region,
  }

  contain cinder::keystone::auth

  class { 'quickstack::cinder':
    user_password => $cinder_user_password,
    db_host       => $mysql_vip,
    db_ssl        => $ssl,
    db_ssl_ca     => $mysql_ca,
    db_password   => $cinder_db_password,
    glance_host   => $glance_private_vip,
    rpc_backend   => amqp_backend('cinder', $amqp_provider),
    amqp_host     => $amqp_vip,
    amqp_port     => $amqp_port,
    amqp_username => $amqp_username,
    amqp_password => $amqp_password,
    qpid_protocol => $qpid_protocol,
    verbose       => $verbose,
  }

  # preserve original behavior - fall back to iscsi
  # https://github.com/redhat-openstack/astapor/blob/7cf25e1022bee08b0c385ae956d4e9e4ade14a9d/puppet/modules/quickstack/manifests/cinder_controller.pp#L85
  if (!str2bool_i("$cinder_backend_gluster") and
      !str2bool_i("$cinder_backend_eqlx") and
      !str2bool_i("$cinder_backend_rbd") and
      !str2bool_i("$cinder_backend_nfs")) {
    $cinder_backend_iscsi_with_fallback = 'true'
  } else {
    $cinder_backend_iscsi_with_fallback = $cinder_backend_iscsi
  }

  if (str2bool_i("$cinder_backend_rbd") or ($glance_backend == 'rbd')) {
    include ::quickstack::ceph::client_packages
    # hack around the glance package declaration if needed
    if ($glance_backend != 'rbd') {
      package {'python-ceph': } -> Class['quickstack::ceph::client_packages']
    }
    if $ceph_fsid {
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

    class {'quickstack::firewall::cinder':}
  }

  class { 'quickstack::cinder_volume':
    backend_eqlx           => $cinder_backend_eqlx,
    backend_eqlx_name      => $cinder_backend_eqlx_name,
    backend_glusterfs      => $cinder_backend_gluster,
    backend_glusterfs_name => $cinder_backend_gluster_name,
    backend_iscsi          => $cinder_backend_iscsi_with_fallback,
    backend_iscsi_name     => $cinder_backend_iscsi_name,
    backend_nfs            => $cinder_backend_nfs,
    backend_nfs_name       => $cinder_backend_nfs_name,
    backend_rbd            => $cinder_backend_rbd,
    backend_rbd_name       => $cinder_backend_rbd_name,
    multiple_backends      => $cinder_multiple_backends,
    # TODO: Create a parameter
    iscsi_bind_addr        => localhost,
    glusterfs_shares       => $cinder_gluster_shares,
    nfs_shares             => $cinder_nfs_shares,
    nfs_mount_options      => $cinder_nfs_mount_options,
    san_ip                 => $cinder_san_ip,
    san_login              => $cinder_san_login,
    san_password           => $cinder_san_password,
    san_thin_provision     => $cinder_san_thin_provision,
    eqlx_group_name        => $cinder_eqlx_group_name,
    eqlx_pool              => $cinder_eqlx_pool,
    eqlx_use_chap          => $cinder_eqlx_use_chap,
    eqlx_chap_login        => $cinder_eqlx_chap_login,
    eqlx_chap_password     => $cinder_eqlx_chap_password,
    rbd_pool               => $cinder_rbd_pool,
    rbd_ceph_conf          => $cinder_rbd_ceph_conf,
    rbd_flatten_volume_from_snapshot
                           => $cinder_rbd_flatten_volume_from_snapshot,
    rbd_max_clone_depth    => $cinder_rbd_max_clone_depth,
    rbd_user               => $cinder_rbd_user,
    rbd_secret_uuid        => $cinder_rbd_secret_uuid,
  }
}
