class quickstack::heat_controller(
  $heat_cfn,
  $heat_cloudwatch,
  $heat_user_password,
  $heat_db_password,
  $controller_priv_host,
  $controller_pub_host,
  $mysql_host,
  $mysql_ca,
  $ssl,
  $qpid_host,
  $qpid_port,
  $qpid_protocol,
  $verbose,
) {

  class {"heat::keystone::auth":
      password => $heat_user_password,
      heat_public_address => $controller_pub_host,
      heat_admin_address => $controller_priv_host,
      heat_internal_address => $controller_priv_host,
      cfn_public_address => $controller_pub_host,
      cfn_admin_address => $controller_priv_host,
      cfn_internal_address => $controller_priv_host,
  }

  class { 'heat':
      keystone_host     => $controller_priv_host,
      keystone_password => $heat_user_password,
      auth_uri          => "http://${controller_priv_host}:35357/v2.0",
      rpc_backend       => 'heat.openstack.common.rpc.impl_qpid',
      qpid_hostname     => $qpid_host,
      qpid_port         => $qpid_port,
      qpid_protocol     => $qpid_protocol,
      verbose           => $verbose,
  }

  class { 'heat::api_cfn':
      enabled => str2bool($heat_cfn),
  }

  class { 'heat::api_cloudwatch':
      enabled => str2bool($heat_cloudwatch),
  }

  class { 'heat::engine':
      heat_metadata_server_url      => "http://${controller_priv_host}:8000",
      heat_waitcondition_server_url => "http://${controller_priv_host}:8000/v1/waitcondition",
      heat_watch_server_url         => "http://${controller_priv_host}:8003",
  }

  class { 'heat::db::mysql':
      password => $heat_db_password,
      allowed_hosts => "%%",
  }

  if str2bool($ssl) {
    $sql_connection = "mysql://heat:${heat_db_password}@${mysql_host}/heat?ssl_ca=${mysql_ca}"
  } else {
    $sql_connection = "mysql://heat:${heat_db_password}@${mysql_host}/heat"
  }

  class { 'heat::db':
      sql_connection => $sql_connection,
  }

  class { 'heat::api':
  }
}
