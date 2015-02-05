class quickstack::heat(
  $heat_user_password      = 'heat',
  $heat_cfn_user_password  = 'heat',
  $auth_encryption_key     = 'heat',
  $bind_host               = '0.0.0.0',
  $db_host                 = '127.0.0.1',
  $db_name                 = 'heat',
  $db_user                 = 'heat',
  $db_password             = '',
  $max_retries             = '',
  $db_ssl                  = false,
  $db_ssl_ca               = '',
  $keystone_host           = '127.0.0.1',
  $qpid_heartbeat          = '60',
  $amqp_host               = '127.0.0.1',
  $amqp_port               = '5672',
  $amqp_username           = '',
  $amqp_password           = '',
  $amqp_provider           = 'rabbitmq',
  $rabbit_use_ssl          = false,
  $rabbit_hosts            = undef,

  $cfn_host                = '127.0.0.1',
  $cloudwatch_host         = '127.0.0.1',

  $use_syslog              = false,
  $log_facility            = 'LOG_USER',

  $enabled                 = true,
  $manage_service          = true,
  $heat_cfn_enabled        = true,
  $heat_cloudwatch_enabled = true,
  $heat_engine_enabled     = true,
  $engine_cfg_delegated    = true,
  $debug                   = false,
  $verbose                 = false,
) {

  if str2bool_i("$db_ssl") {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?ssl_ca=${db_ssl_ca}"
  } else {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
  }

  class {'::quickstack::firewall::heat':
    heat_cfn_enabled        => $heat_cfn_enabled,
    heat_cloudwatch_enabled => $heat_cloudwatch_enabled,
  }

  if $max_retries {
    heat_config {
      'DEFAULT/max_retries':      value => $max_retries;
    }
  }

  class { '::heat':
    sql_connection    => $sql_connection,
    keystone_ec2_uri  => "http://${keystone_host}:35357/v2.0/ec2tokens",
    auth_uri          => "http://${keystone_host}:35357/v2.0",
    keystone_password => $heat_user_password,
    keystone_tenant   => "services",
    keystone_user     => "heat",
    keystone_host     => $keystone_host,
    rpc_backend       => amqp_backend('heat', $amqp_provider),
    qpid_heartbeat    => $qpid_heartbeat,
    qpid_hostname     => $amqp_host,
    qpid_port         => $amqp_port,
    qpid_username     => $amqp_username,
    qpid_password     => $amqp_password,
    rabbit_host       => $amqp_host,
    rabbit_port       => $amqp_port,
    rabbit_userid     => $amqp_username,
    rabbit_password   => $amqp_password,
    rabbit_use_ssl    => $rabbit_use_ssl,
    rabbit_hosts      => $rabbit_hosts,
    use_syslog        => str2bool_i("$use_syslog"),
    log_facility      => $log_facility,
    verbose           => $verbose,
    debug             => $debug,
  }
  # FIXME(jistr): after we drop support for Puppet <= 3.6, we can use
  # `contain ::heat` instead of the anchors here, and use fully qualified
  # class names in the rest of `contain` statements too
  anchor { 'quickstack-heat-first': } ->
  Class['::heat'] ->
  anchor { 'quickstack-heat-last': }

  class { '::heat::api':
    bind_host      => $bind_host,
    enabled        => str2bool_i("$enabled"),
    manage_service => str2bool_i("$manage_service"),
  }
  contain heat::api

  class { '::heat::api_cfn':
    # Currently api_cfn module doesn't support setting these
    # keystone_password => $heat_cfn_user_password,
    # keystone_user     => "heat-cfn",
    bind_host         => $bind_host,
    enabled           => str2bool_i("$heat_cfn_enabled"),
    manage_service    => str2bool_i("$manage_service"),
  }
  contain heat::api_cfn

  class { '::heat::api_cloudwatch':
    bind_host         => $bind_host,
    enabled           => str2bool_i("$heat_cloudwatch_enabled"),
    manage_service    => str2bool_i("$manage_service"),
  }
  contain heat::api_cloudwatch

  class { '::heat::engine':
    auth_encryption_key           => $auth_encryption_key,
    heat_metadata_server_url      => "http://${cfn_host}:8000",
    heat_waitcondition_server_url => "http://${cfn_host}:8000/v1/waitcondition",
    heat_watch_server_url         => "http://${cloudwatch_host}:8003",
    enabled                       => str2bool_i("$heat_engine_enabled"),
    manage_service                => str2bool_i("$manage_service"),
    configure_delegated_roles     => $engine_cfg_delegated,
  }
}
