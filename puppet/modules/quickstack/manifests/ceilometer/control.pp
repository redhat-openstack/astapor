class quickstack::ceilometer::control(
  $amqp_provider,
  $amqp_host                  = '127.0.0.1',
  $amqp_port                  = '5672',
  $amqp_username,
  $amqp_password,
  $rabbit_hosts               = undef,
  $auth_host                  = '127.0.0.1',
  $bind_address               = '0.0.0.0',
  $ceilometer_metering_secret,
  $ceilometer_user_password,
  $ceilometer_admin_host      = '127.0.0.1',
  $ceilometer_priv_host       = '127.0.0.1',
  $ceilometer_pub_host        = '127.0.0.1',
  $db_hosts                   = ['127.0.0.1:27017'],
  $memcache_servers           = ['127.0.0.1:11211'],
  $qpid_protocol              = 'tcp',
  $service_enable             = true,
  $service_ensure             = 'running',
  $verbose                    = false,
) {

  validate_array($db_hosts)
  validate_array($memcache_servers)
  $_db_hosts = join($db_hosts, ",")
  $_db_conn = "mongodb://${_db_hosts}/ceilometer?replicaSet=ceilometer"

  ceilometer_config {
    'DEFAULT/memcache_servers' : value => join($memcache_servers,",");
    'database/max_retries'     : value => '-1';
  }

  class { '::ceilometer::db':
    database_connection => $_db_conn,
    sync_db             => $service_enable,
    # hopefully we dont really need this, as it couples our setup to the
    # assumption that we use mongo and are the ones configuring it.
    require             => Anchor['mongodb setup done'],
  }

  class { '::ceilometer':
    metering_secret => $ceilometer_metering_secret,
    qpid_hostname   => $amqp_host,
    qpid_port       => $amqp_port,
    qpid_protocol   => $qpid_protocol,
    qpid_username   => $amqp_username,
    qpid_password   => $amqp_password,
    rabbit_host     => $amqp_host,
    rabbit_port     => $amqp_port,
    rabbit_userid   => $amqp_username,
    rabbit_password => $amqp_password,
    rabbit_hosts    => $rabbit_hosts,
    rpc_backend     => amqp_backend('ceilometer', $amqp_provider),
    verbose         => str2bool_i("$verbose"),
  }

  class { '::ceilometer::collector':
    enabled        => $service_enable,
    manage_service => $service_enable,
    require => Class['::ceilometer::db'],
  }

  class { '::ceilometer::agent::notification':
    enabled        => $service_enable,
    manage_service => $service_enable,
  }

  class { '::ceilometer::agent::auth':
    auth_url      => "http://${auth_host}:35357/v2.0",
    auth_password => $ceilometer_user_password,
  }

  class { '::ceilometer::agent::central':
    enabled        => $service_enable,
    manage_service => $service_enable,
  }

  class { '::ceilometer::alarm::notifier':
    enabled        => $service_enable,
    manage_service => $service_enable,
  }

  class { '::ceilometer::alarm::evaluator':
    enabled        => $service_enable,
    manage_service => $service_enable,
  }

  class { '::ceilometer::api':
    enabled           => $service_enable,
    host              => $bind_address,
    keystone_host     => $auth_host,
    keystone_password => $ceilometer_user_password,
    manage_service    => $service_enable,
    require           => Anchor['mongodb setup done'],
  }

  # Configure TTL for samples
  # Purge data older than one month
  # Run the script once a day but with a random time to avoid
  # issues with MongoDB access
  class { '::ceilometer::expirer':
    time_to_live => '432000',
    minute   => '0',
    hour => '0',
  }

  Cron <<| title == 'ceilometer-expirer' |>> {
    command => "sleep $((\$RANDOM % 86400)) &&
                ${::ceilometer::params::expirer_command}"
  }
}
