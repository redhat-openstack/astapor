#
class quickstack::roles::control::heat (
  $heat_vip_admin,
  $heat_vip_internal,
  $heat_vip_public,
  $heat_db_password,
  $heat_user_password,
  $heat_auth_encrypt_key,
  $public_protocol  = 'http',
  $verbose = 'false',
) inherits quickstack::roles::params {

  class { 'heat::keystone::auth':
    password         => $heat_user_password,
    public_address   => $heat_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $heat_vip_admin,
    internal_address => $heat_vip_internal,
    region           => $region,
  }

  $amqp_port = amqp_port(str2bool_i("$ssl"))
  $qpid_protocol = qpid_protocol(str2bool_i("$ssl"))
  $url_ssl = url_ssl($ssl, $mysql_ca)
  $sql_connection = "mysql://heat:${heat_db_password}@${mysql_host}/heat${url_ssl}"

  class { '::heat':
      keystone_host     => $controller_priv_host,
      keystone_password => $heat_user_password,
      auth_uri          => "http://${controller_priv_host}:35357/v2.0",
      rpc_backend       => amqp_backend('heat', $amqp_provider),
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

  class { '::heat::api':}

  class {'quickstack::firewall::heat':}
}
