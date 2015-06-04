class quickstack::ceph::client_packages {

  $ceph_client_packages = ['librados2','librbd1','ceph-common']

  package { $ceph_client_packages: ensure => "installed" }
}
