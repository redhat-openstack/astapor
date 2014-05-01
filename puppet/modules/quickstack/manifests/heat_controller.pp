class quickstack::heat_controller(
  $auth_encryption_key,
  $heat_cfn,
  $heat_cloudwatch,
  $heat_user_password,
  $heat_db_password,
  $controller_admin_host,
  $controller_priv_host,
  $controller_pub_host,
  $mysql_ca,
  $mysql_host,
  $ssl,
  $amqp_server,
  $amqp_host,
  $amqp_port,
  $qpid_protocol,
  $amqp_username,
  $amqp_password,
  $verbose,
) {

  if str2bool_i("$ssl") {
    $sql_connection = "mysql://heat:${heat_db_password}@${mysql_host}/heat?ssl_ca=${mysql_ca}"
  } else {
    $sql_connection = "mysql://heat:${heat_db_password}@${mysql_host}/heat"
  }
  class {"::heat::keystone::auth":
      password         => $heat_user_password,
      public_address   => $controller_pub_host,
      admin_address    => $controller_priv_host,
      internal_address => $controller_priv_host,
  }

  class {"::heat::keystone::auth_cfn":
      password         => $heat_user_password,
      public_address   => $controller_pub_host,
      admin_address    => $controller_priv_host,
      internal_address => $controller_priv_host,
  }

  class { '::heat':
      keystone_host     => $controller_priv_host,
      keystone_password => $heat_user_password,
      auth_uri          => "http://${controller_priv_host}:35357/v2.0",
      rpc_backend       => amqp_backend('heat', $amqp_server),
      qpid_hostname     => $amqp_host,
      qpid_port         => $amqp_port,
      qpid_protocol     => $qpid_protocol,
      qpid_username     => $amqp_username,
      qpid_password     => $amqp_password,
      rabbit_host       => $amqp_host,
      rabbit_port       => $amqp_port,
      rabbit_userid     => $amqp_username,
      rabbit_password   => $amqp_password,
      verbose           => $verbose,
      sql_connection    => $sql_connection,
  }

  class { '::heat::api_cfn':
      enabled => str2bool_i("$heat_cfn"),
  }

  class { '::heat::api_cloudwatch':
      enabled => str2bool_i("$heat_cloudwatch"),
  }

  class { '::heat::engine':
      auth_encryption_key           => $auth_encryption_key,
      heat_metadata_server_url      => "http://${controller_priv_host}:8000",
      heat_waitcondition_server_url => "http://${controller_priv_host}:8000/v1/waitcondition",
      heat_watch_server_url         => "http://${controller_priv_host}:8003",
  }

  # TODO: this ain't no place to be creating a db locally as happens below
  class { 'heat::db::mysql':
    password      => $heat_db_password,
    host          => $mysql_host,
    allowed_hosts => "%%",
  }

  class { '::heat::api':
  }
}
