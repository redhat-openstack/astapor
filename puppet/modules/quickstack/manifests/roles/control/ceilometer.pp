#
class quickstack::roles::control::ceilometer (
  $public_protocol = 'http',
  $verbose         = 'false',
) inherits quickstack::roles::params {

  $amqp_port     = amqp_port(str2bool_i("$ssl"))
  $qpid_protocol = qpid_protocol(str2bool_i("$ssl"))

  class { '::ceilometer::keystone::auth':
    password         => $ceilometer_user_password,
    public_address   => $ceilometer_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $ceilometer_vip_admin,
    internal_address => $ceilometer_vip_internal,
    region           => $region,
  }

  class { '::mongodb::server':
      port => '27017',
  }
  ->
  # FIXME: passwordless connection is insecure, also we might use a
  # way to run mongo on a different host in the future
  class { '::ceilometer::db':
      database_connection => 'mongodb://localhost:27017/ceilometer',
      require             => Service['mongod'],
  }

  class { '::ceilometer':
      metering_secret => $ceilometer_metering_secret,
      qpid_hostname   => $amqp_vip,
      qpid_port       => $amqp_port,
      qpid_protocol   => $qpid_protocol,
      qpid_username   => $amqp_username,
      qpid_password   => $amqp_password,
      rabbit_host     => $amqp_vip,
      rabbit_port     => $amqp_port,
      rabbit_userid   => $amqp_username,
      rabbit_password => $amqp_password,
      rpc_backend     => amqp_backend('ceilometer', $amqp_provider),
      verbose         => $verbose,
  }

  class { '::ceilometer::collector':
      require => Class['ceilometer::db'],
  }

  class { '::ceilometer::agent::notification':}

  class { '::ceilometer::agent::auth':
      auth_url      => "http://${keystone_vip_internal}:35357/v2.0",
      auth_password => $ceilometer_user_password,
  }

  class { '::ceilometer::agent::central':
      enabled => true,
  }

  class { '::ceilometer::alarm::notifier':
  }

  class { '::ceilometer::alarm::evaluator':
  }

  class { '::ceilometer::api':
      keystone_host     => $keystone_vip_internal,
      keystone_password => $ceilometer_user_password,
      require           => Service['mongod'],
  }

  # class {'quickstack::firewall::ceilometer':}
}
