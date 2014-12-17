#
# == Class: quickstack::keystone::common
#
# Installs and configures Keystone
#
# === Parameters
#
# [admin_token]. Auth token for keystone admin. Required.
# [bind_host] Address that keystone binds to. Optional. Defaults to  '0.0.0.0'
# [db_host] Host where DB resides. Optional. Defaults to 127.0.0.1..
# [db_name] Name of keystone DB. Optional. Defaults to  'keystone'
# [db_password] Password for keystone DB. Required.
# [db_ssl] Boolean whether to use SSL for database. Defaults to false.
# [db_ssl_ca] If db_ssl is true, this is used in the connection to define the CA. Default undef.
# [db_type] Type of DB used. Currently only supports mysql. Optional. Defaults to  'mysql'
# [db_user] Name of keystone db user. Optional. Defaults to  'keystone'
# [debug] Log at a debug-level. Optional. Defaults to false.
# [idle_timeout] Timeout to reap SQL connections. Optional. Defaults to '200'.
# [log_facility] Syslog facility to receive log lines. Defaults to LOG_USER.
# [enabled] If the service is active (true) or passive (false).
#   Optional. Defaults to  true
# [manage_service] Whether puppet it to manage if the service is running or not.
#   Optional. Defaults to true
# [token_driver] Driver to use for managing tokens.
#   Optional.  Defaults to 'keystone.token.backends.sql.Token'
# [token_format] Format keystone uses for tokens. Optional. Defaults to PKI.
#   Supports PKI and UUID.
# [use_syslog] Use syslog for logging. Defaults to false.
# [verbose] Log verbosely. Optional. Defaults to false.
#
# === Example
#
# class { 'quickstack::keystone:common':
#   db_host               => '127.0.0.1',
#   db_password           => 'changeme',
#   admin_token           => '12345',
#  }

class quickstack::keystone::common (
  $admin_token,
  $bind_host                   = '0.0.0.0',
  $db_host                     = '127.0.0.1',
  $db_name                     = 'keystone',
  $db_password,
  $db_ssl                      = false,
  $db_ssl_ca                   = undef,
  $db_type                     = 'mysql',
  $db_user                     = 'keystone',
  $debug                       = false,
  $enabled                     = true,
  $idle_timeout                = '200',
  $log_facility                = 'LOG_USER',
  $token_driver                = 'keystone.token.backends.sql.Token',
  $token_format                = 'PKI',
  $use_syslog                  = false,
  $verbose                     = false,
) {

  # Install and configure Keystone
  if $db_type == 'mysql' {
    if $db_ssl == true {
      $sql_conn = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?ssl_ca=${db_ssl_ca}"
    } else {
      $sql_conn = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
    }
  } else {
    fail("db_type ${db_type} is not supported")
  }

  class { '::keystone':
    admin_token    => $admin_token,
    bind_host      => $bind_host,
    catalog_type   => 'sql',
    debug          => $debug,
    enabled        => $enabled,
    idle_timeout   => $idle_timeout,
    log_facility   => $log_facility,
    sql_connection => $sql_conn,
    token_driver   => $token_driver,
    token_format   => $token_format,
    use_syslog     => $use_syslog,
    verbose        => $verbose,
  }
  contain keystone

  include ::quickstack::cron::keystone_token
}
