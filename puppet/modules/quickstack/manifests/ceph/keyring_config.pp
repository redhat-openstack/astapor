define quickstack::ceph::keyring_config (
  $key = '',
  $keyring_filename = '',
  $caps_mon = 'allow r',
  $caps_osd = "allow class-read object_prefix rbd_children, allow rwx pool=${title}",
) {
  $keyring_name = $title
  if $keyring_filename {
    $_keyring_filename = $keyring_filename
  } else {
    $_keyring_filename = "/etc/ceph/ceph.client.${keyring_name}.keyring"
  }
  file { "etc-ceph-keyring-${keyring_name}":
    path => $_keyring_filename,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('quickstack/ceph-keyring.erb'),
  }
}
