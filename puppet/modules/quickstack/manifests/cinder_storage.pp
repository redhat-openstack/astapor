class quickstack::cinder_storage(
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $controller_priv_fqdn = $quickstack::params::controller_priv_fqdn,
  $private_interface           = $quickstack::params::private_interface,
  $mysql_host                  = $quickstack::params::mysql_host,
  $qpid_host                   = $quickstack::params::qpid_host,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {

  class { 'cinder':
    rpc_backend    => 'cinder.openstack.common.rpc.impl_qpid',
    qpid_hostname  => $qpid_host,
    qpid_password  => 'guest',
    sql_connection => "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder",
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
