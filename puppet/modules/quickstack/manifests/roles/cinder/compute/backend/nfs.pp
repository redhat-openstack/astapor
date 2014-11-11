class quickstack::roles::cinder::compute::backend::nfs (
) {

  package { 'nfs-utils':
    ensure => 'present',
  }

  if ($::selinux != "false") {
    selboolean{'virt_use_nfs':
        value => on,
        persistent => true,
    }
  }
}
