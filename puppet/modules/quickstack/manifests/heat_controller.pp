class quickstack::heat_controller(
  $heat_cfn,
  $heat_cloudwatch,
  $heat_user_password,
  $heat_db_password,
  $controller_priv_floating_ip,
  $controller_pub_floating_ip,
  $mysql_host,
  $qpid_host,
  $qpid_username,
  $qpid_password,
  $verbose,
) {

  class {"heat::keystone::auth":
      password => $heat_user_password,
      heat_public_address => $controller_pub_floating_ip,
      heat_admin_address => $controller_priv_floating_ip,
      heat_internal_address => $controller_priv_floating_ip,
      cfn_public_address => $controller_pub_floating_ip,
      cfn_admin_address => $controller_priv_floating_ip,
      cfn_internal_address => $controller_priv_floating_ip,
  }

  class { 'heat':
      keystone_host     => $controller_priv_floating_ip,
      keystone_password => $heat_user_password,
      auth_uri          => "http://${controller_priv_floating_ip}:35357/v2.0",
      rpc_backend       => 'heat.openstack.common.rpc.impl_qpid',
      qpid_hostname     => $qpid_host,
      qpid_username     => $qpid_username,
      qpid_password     => $qpid_password,
      verbose           => $verbose,
  }

  class { 'heat::api_cfn':
      enabled => str2bool($heat_cfn),
  }

  class { 'heat::api_cloudwatch':
      enabled => str2bool($heat_cloudwatch),
  }

  class { 'heat::engine':
      heat_metadata_server_url      => "http://${controller_priv_floating_ip}:8000",
      heat_waitcondition_server_url => "http://${controller_priv_floating_ip}:8000/v1/waitcondition",
      heat_watch_server_url         => "http://${controller_priv_floating_ip}:8003",
  }

  class { 'heat::db::mysql':
      password => $heat_db_password,
      allowed_hosts => "%%",
  }

  class { 'heat::db':
      sql_connection => "mysql://heat:${heat_db_password}@${mysql_host}/heat",
  }

  class { 'heat::api':
  }
}
