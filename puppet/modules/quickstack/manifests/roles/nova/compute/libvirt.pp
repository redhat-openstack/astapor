class quickstack::roles::nova::compute::libvirt (
  # kvm or qemu
  $libvirt_type = 'kvm',
) inherits quickstack::roles::params {

  class { '::nova::compute::libvirt':
    libvirt_type => $libvirt_type,
    vncserver_listen => '0.0.0.0',
  }

  nova_config {
    'DEFAULT/libvirt_inject_partition':     value => '-1';
  }
}
