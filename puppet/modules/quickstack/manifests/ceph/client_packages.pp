class quickstack::ceph::client_packages {

  $ceph_client_packages = ['librados2','librbd1','ceph-common']

  # if and when glance::backend::rbd stops declaring python-ceph,
  # we can instead declare all ceph client packages below
  # $ceph_client_packages = ['librados2','librbd1','ceph-common','python-ceph']

  package { $ceph_client_packages: ensure => "installed" }
}
