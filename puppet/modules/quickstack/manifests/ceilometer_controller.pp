class quickstack::ceilometer_controller(
  $ceilometer_metering_secret,
  $ceilometer_user_password,
  $controller_priv_floating_ip,
  $controller_pub_floating_ip,
  $qpid_host,
  $qpid_username,
  $qpid_password,
  $verbose,
) {

    class { 'ceilometer::keystone::auth':
        password => $ceilometer_user_password,
        public_address => $controller_pub_floating_ip,
        admin_address => $controller_priv_floating_ip,
        internal_address => $controller_priv_floating_ip,
    }

    class { 'mongodb':
       enable_10gen => false,
       port         => '27017',
    }

    class { 'ceilometer':
        metering_secret => $ceilometer_metering_secret,
        qpid_hostname   => $qpid_host,
        qpid_username   => $qpid_username,
        qpid_password   => $qpid_password,
        rpc_backend     => 'ceilometer.openstack.common.rpc.impl_qpid',
        verbose         => $verbose,
    }

    # FIXME: passwordless connection is insecure, also we might use a
    # way to run mongo on a different host in the future
    class { 'ceilometer::db':
        database_connection => 'mongodb://localhost:27017/ceilometer',
        require             => Class['mongodb'],
    }

    class { 'ceilometer::collector':
        require => Class['ceilometer::db'],
    }

    class { 'ceilometer::agent::auth':
        auth_url      => "http://${controller_priv_floating_ip}:35357/v2.0",
        auth_password => $ceilometer_user_password,
    }

    class { 'ceilometer::agent::central':
        enabled => true,
    }

    class { 'ceilometer::api':
        keystone_host     => $controller_priv_floating_ip,
        keystone_password => $ceilometer_user_password,
        require           => Class['mongodb'],
    }

    glance_api_config {
        'DEFAULT/notifier_strategy': value => 'qpid'
    }
}
