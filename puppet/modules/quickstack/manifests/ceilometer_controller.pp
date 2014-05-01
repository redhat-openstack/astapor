class quickstack::ceilometer_controller(
  $ceilometer_metering_secret,
  $ceilometer_user_password,
  $controller_admin_host,
  $controller_priv_host,
  $controller_pub_host,
  $amqp_server,
  $amqp_host,
  $amqp_port = '5672',
  $qpid_protocol = 'tcp',
  $amqp_username,
  $amqp_password,
  $verbose,
) {

    class { 'ceilometer::keystone::auth':
        password => $ceilometer_user_password,
        public_address => $controller_pub_host,
        admin_address => $controller_admin_host,
        internal_address => $controller_priv_host,
    }

    class { 'mongodb::server':
        port => '27017',
    }
    ->
    # FIXME: passwordless connection is insecure, also we might use a
    # way to run mongo on a different host in the future
    class { 'ceilometer::db':
        database_connection => 'mongodb://localhost:27017/ceilometer',
    }

    class { 'ceilometer':
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
        rpc_backend     => amqp_backend('ceilometer', $amqp_server),
        verbose         => $verbose,
    }

    class { 'ceilometer::collector':
        require => Class['ceilometer::db'],
    }

    class { 'ceilometer::agent::auth':
        auth_url      => "http://${controller_priv_host}:35357/v2.0",
        auth_password => $ceilometer_user_password,
    }

    class { 'ceilometer::agent::central':
        enabled => true,
    }

    class { 'ceilometer::api':
        keystone_host     => $controller_priv_host,
        keystone_password => $ceilometer_user_password,
    }
}
