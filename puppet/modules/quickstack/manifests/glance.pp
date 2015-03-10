# A minor variation of openstack::glance
#  - expose $filesystem_store_datadir
#  - default values of '' for swift_store_user and swift_store_key
#    instead of false which is more consistent with existing
#    quickstack manifests and better for foreman Host Group Parameters
#    UI (because a param is either a boolean or a string from
#    Foreman's perspective, not dynamically decided based on whatever
#    the users feels like passing in).
# - expose qpid_ vars

class quickstack::glance (
  $user_password            = 'glance',
  $db_password              = '',
  $db_host                  = '127.0.0.1',
  $keystone_host            = '127.0.0.1',
  $sql_idle_timeout         = '3600',
  $registry_host            = '0.0.0.0',
  $bind_host                = '0.0.0.0',
  $db_ssl                   = false,
  $db_ssl_ca                = '',
  $db_user                  = 'glance',
  $db_name                  = 'glance',
  $max_retries              = '',
  $backend                  = 'file',
  $rbd_store_user           = 'images',
  $rbd_store_pool           = 'images',
  $swift_store_user         = '',
  $swift_store_key          = '',
  $swift_store_auth_address = 'http://127.0.0.1:5000/v2.0/',
  $verbose                  = false,
  $debug                    = false,
  $use_syslog               = false,
  $log_facility             = 'LOG_USER',
  $enabled                  = true,
  $manage_service           = true,
  $filesystem_store_datadir = '/var/lib/glance/images/',
  $amqp_host                = '127.0.0.1',
  $amqp_port                = '5672',
  $amqp_username            = '',
  $amqp_password            = '',
  $amqp_provider            = 'rabbitmq',
  $rabbit_use_ssl           = false,
  $rabbit_hosts             = undef,
) {

  # Configure the db string
  if $db_ssl == true {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?ssl_ca=${db_ssl_ca}"
  } else {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
  }

  $_auth_url = "http://${keystone_host}:5000/v2.0"

  if ($backend == 'file') {
    $_backend = 'filesystem'
  } else {
    $_backend = $backend
  }

  $show_image_direct_url = $backend ? {
    'rbd' => true,
    default => false,
  }

  if $rabbit_hosts {
    glance_api_config { 'DEFAULT/rabbit_host': ensure => absent }
    glance_api_config { 'DEFAULT/rabbit_port': ensure => absent }
  }

  # Install and configure glance-api
  class { '::glance::api':
    verbose               => $verbose,
    debug                 => $debug,
    registry_host         => $registry_host,
    bind_host             => $bind_host,
    auth_type             => 'keystone',
    auth_port             => '35357',
    auth_host             => $keystone_host,
    auth_url              => $_auth_url,
    keystone_tenant       => 'services',
    keystone_user         => 'glance',
    keystone_password     => $user_password,
    known_stores          => ["glance.store.${_backend}.Store"],
    sql_connection        => $sql_connection,
    sql_idle_timeout      => $sql_idle_timeout,
    use_syslog            => $use_syslog,
    log_facility          => $log_facility,
    enabled               => $enabled,
    manage_service        => $manage_service,
    show_image_direct_url => $show_image_direct_url,
  }
  contain glance::api

  # Install and configure glance-registry
  class { '::glance::registry':
    verbose           => $verbose,
    debug             => $debug,
    bind_host         => $bind_host,
    auth_host         => $keystone_host,
    auth_port         => '35357',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $user_password,
    sql_connection    => $sql_connection,
    sql_idle_timeout  => $sql_idle_timeout,
    use_syslog        => $use_syslog,
    log_facility      => $log_facility,
    enabled           => $enabled,
    manage_service    => $manage_service,
  }
  contain glance::registry

  if $max_retries {
    glance_api_config {
      'DEFAULT/max_retries':      value => $max_retries;
    }
    glance_registry_config {
      'DEFAULT/max_retries':      value => $max_retries;
    }
  }
  if ($amqp_provider == 'qpid') {
    class { 'glance::notify::qpid':
      qpid_password => $amqp_password,
      qpid_username => $amqp_username,
      qpid_hostname => $amqp_host,
      qpid_port     => $amqp_port,
      qpid_protocol => 'tcp',
    }
  } else {
    class { 'glance::notify::rabbitmq':
      rabbit_password => $amqp_password,
      rabbit_userid   => $amqp_username,
      rabbit_host     => $amqp_host,
      rabbit_port     => $amqp_port,
      rabbit_use_ssl  => $rabbit_use_ssl,
      rabbit_hosts    => $rabbit_hosts,
    }
  }

  # Configure file storage backend
  if($backend == 'swift') {
    if ! $swift_store_user {
      fail('swift_store_user must be set when configuring swift as the glance backend')
    }
    if ! $swift_store_key {
      fail('swift_store_key must be set when configuring swift as the glance backend')
    }

    class { 'glance::backend::swift':
      swift_store_user                    => $swift_store_user,
      swift_store_key                     => $swift_store_key,
      swift_store_auth_address            => $swift_store_auth_address,
      swift_store_create_container_on_put => true,
    }
  } elsif($backend == 'file') {
    class { 'glance::backend::file':
      filesystem_store_datadir => $filesystem_store_datadir,
    }
  } elsif($backend == 'rbd') {
    Class['quickstack::ceph::client_packages'] ->
    class { 'glance::backend::rbd':
      rbd_store_user => $rbd_store_user,
      rbd_store_pool => $rbd_store_pool,
    }
  } else {
    fail("Unsupported backend ${backend}")
  }
  class {'::quickstack::firewall::glance':}
}
