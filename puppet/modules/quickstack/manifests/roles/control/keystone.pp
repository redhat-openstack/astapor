#
class quickstack::roles::control::keystone (
  $admin_token,
  $db_name        = 'keystone',
  $debug          = 'false',
  $bind_address   = '0.0.0.0',
  $enabled        = 'true',
  $idle_timeout   = '200',
  $log_facility   = 'LOG_USER',
  $manage_service = 'true',
  $token_driver   = 'keystone.token.backends.sql.Token',
  $token_format   = 'PKI',
  $use_syslog     = 'true',
  $verbose        = 'false',
) inherits quickstack::roles::params {

  # Install and configure Keystone
  if $db_type == 'mysql' {
    $url_ssl = url_ssl($ssl, $mysql_ca)
    $sql_connection = "mysql://${keystone_db_user}:${keystone_db_password}@${mysql_vip}/${db_name}${url_ssl_ca}"
  } else {
    fail("db_type ${db_type} is not supported")
  }

  class { '::keystone':
    admin_token    => $admin_token,
    bind_host      => $bind_address,
    catalog_type   => 'sql',
    debug          => $debug,
    enabled        => $enabled,
    idle_timeout   => $idle_timeout,
    log_facility   => $log_facility,
    manage_service => $manage_service,
    sql_connection => $sql_connection,
    token_driver   => $token_driver,
    token_format   => $token_format,
    use_syslog     => $use_syslog,
    verbose        => $verbose,
  }
  contain keystone

  # Setup the admin user
  class { 'keystone::roles::admin':
    email        => $admin_email,
    password     => $admin_password,
    admin_tenant => $admin_tenant,
  }
  contain keystone::roles::admin

  # Setup the Keystone Identity Endpoint
  class { 'keystone::endpoint':
    public_address   => $public_address,
    public_protocol  => $public_protocol,
    admin_address    => $keystone_vip_admin,
    internal_address => $keystone_vip_internal,
    region           => $region,
  }

  contain keystone::endpoint

  class {'quickstack::firewall::keystone':}

}
