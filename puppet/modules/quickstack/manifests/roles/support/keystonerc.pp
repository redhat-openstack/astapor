#
class quickstack::roles::support::keystonerc ()
  inherits quickstack::roles::params {

  class { 'quickstack::admin_client':
    admin_password        => $admin_password,
    controller_admin_host => $keystone_vip_admin,
  }
}
