class quickstack::roles::cinder::compute::backend::rbd (
) {

  if str2bool_i("$cinder_backend_rbd") {
    nova_config {
      'DEFAULT/libvirt_images_rbd_pool':      value => $libvirt_images_rbd_pool;
      'DEFAULT/libvirt_images_rbd_ceph_conf': value => $libvirt_images_rbd_ceph_conf;
      'DEFAULT/libvirt_inject_password':      value => $libvirt_inject_password;
      'DEFAULT/libvirt_inject_key':           value => $libvirt_inject_key;
    # https://bugs.launchpad.net/nova/+bug/1257674
      'DEFAULT/libvirt_inject_partition':     value => '-2';
      'DEFAULT/libvirt_images_type':          value => $libvirt_images_type;
      'DEFAULT/rbd_user':                     value => $cinder_rbd_user;
      'DEFAULT/rbd_secret_uuid':              value => $rbd_secret_uuid;
    }

    # the rest of this if block is borrowed from ::nova::compute::rbd
    # which we can't use due to a duplicate package declaration
    file { '/etc/nova/secret.xml':
      content => template('quickstack/compute-volumes-rbd-secret-xml.erb')
    }
    ->
    Class['quickstack::ceph::client_packages']
    ->
    Service[libvirt]
    ->
    exec { 'define-virsh-rbd-secret':
      command => '/usr/bin/virsh secret-define --file /etc/nova/secret.xml',
      onlyif => "/usr/bin/ceph --connect-timeout 10 auth get-key client.${libvirt_images_rbd_pool} >/dev/null 2>&1",
      creates => '/etc/nova/virsh.secret',
    }
    ->
    exec { 'set-virsh-rbd-secret-key':
      command => "/usr/bin/virsh secret-set-value --secret ${rbd_secret_uuid} --base64 \$(/usr/bin/ceph auth get-key client.${libvirt_images_rbd_pool})",
      onlyif => "/usr/bin/ceph --connect-timeout 10 auth get-key client.${libvirt_images_rbd_pool} >/dev/null 2>&1",
    }
  }
}
