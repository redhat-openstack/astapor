class quickstack::cinder(
  $user_password  = 'cinder',
  $bind_host      = '0.0.0.0',
  $db_host        = '127.0.0.1',
  $db_name        = 'cinder',
  $db_user        = 'cinder',
  $db_password    = '',
  $max_retries    = '',
  $db_ssl         = false,
  $db_ssl_ca      = '',
  $glance_host    = '127.0.0.1',
  $keystone_host  = '127.0.0.1',
  $use_syslog     = false,
  $log_facility   = 'LOG_USER',

  $rpc_backend    = 'cinder.openstack.common.rpc.impl_kombu',
  $amqp_host      = '127.0.0.1',
  $amqp_port      = '5672',
  $amqp_username  = '',
  $amqp_password  = '',
  $qpid_heartbeat = '60',
  $qpid_protocol  = 'tcp',
  $rabbit_use_ssl = false,
  $rabbit_hosts   = undef,

  $enabled        = true,
  $manage_service = true,
  $debug          = false,
  $verbose        = false,
) {
  include ::quickstack::firewall::cinder

  $amqp_password_safe_for_cinder = $amqp_password ? {
    ''      => 'guest',
    false   => 'guest',
    default => $amqp_password,
  }

  cinder_config {
    'DEFAULT/glance_host': value => $glance_host;
    'DEFAULT/notification_driver': value => 'cinder.openstack.common.notifier.rpc_notifier'
  }
  if $max_retries {
    cinder_config {
      'DEFAULT/max_retries':      value => $max_retries;
    }
  }

  if str2bool_i("$db_ssl") {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?ssl_ca=${db_ssl_ca}"
  } else {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
  }

  class {'::cinder':
    rpc_backend         => $rpc_backend,
    qpid_hostname       => $amqp_host,
    qpid_port           => $amqp_port,
    qpid_username       => $amqp_username,
    qpid_password       => $amqp_password_safe_for_cinder,
    qpid_heartbeat      => $qpid_heartbeat,
    qpid_protocol       => $qpid_protocol,
    rabbit_host         => $amqp_host,
    rabbit_port         => $amqp_port,
    rabbit_userid       => $amqp_username,
    rabbit_password     => $amqp_password_safe_for_cinder,
    rabbit_use_ssl      => $rabbit_use_ssl,
    rabbit_hosts        => $rabbit_hosts,
    database_connection => $sql_connection,
    verbose             => str2bool_i("$verbose"),
    use_syslog          => str2bool_i("$use_syslog"),
    log_facility        => $log_facility,
  }
  # FIXME: after we drop support for Puppet <= 3.6, we can use
  # `contain ::cinder` instead of the anchors here, and use fully qualified
  # class names in the rest of `contain` statements too
  anchor { 'quickstack-cinder-first': } ->
  Class['::cinder'] ->
  anchor { 'quickstack-cinder-last': }

  class {'::cinder::api':
    keystone_password  => $user_password,
    keystone_tenant    => "services",
    keystone_user      => "cinder",
    keystone_auth_host => $keystone_host,
    enabled            => str2bool_i("$enabled"),
    manage_service     => str2bool_i("$manage_service"),
    bind_host          => $bind_host,
  }

  class {'::cinder::scheduler':
    enabled        => str2bool_i("$enabled"),
    manage_service => str2bool_i("$manage_service"),
  }
}
