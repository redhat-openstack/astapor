class quickstack::cinder_storage(
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $private_interface           = $quickstack::params::private_interface,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {

  class { 'cinder':
    rpc_backend    => 'cinder.openstack.common.rpc.impl_qpid',
    qpid_hostname  => $controller_priv_floating_ip,
    qpid_password  => 'guest',
    sql_connection => "mysql://cinder:${cinder_db_password}@${controller_priv_floating_ip}/cinder",
    verbose        => $verbose,
  }

  class { 'cinder::volume': }

  class { 'cinder::volume::iscsi':
    iscsi_ip_address => getvar("ipaddress_${private_interface}"),
  }

  firewall { '010 cinder iscsi':
      proto => 'tcp',
      dport => ['3260'],
      action => 'accept',
  }
}
