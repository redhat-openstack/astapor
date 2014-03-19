class quickstack::swift::proxy (
  $controller_pub_host, # a better param name might be $swift_proxy_ip
  $swift_admin_password,
  $swift_shared_secret,
  $swift_ringserver_ip,   # for swift-only traffic
  $swift_is_ringserver,
  # below two values only matter if $swift_is_ringserver is true
  # when the rings are built
  $swift_storage_ips,
  $swift_storage_device,
) inherits quickstack::params {

    #### Swift ####
    package { 'curl': ensure => present }

    class { '::swift::proxy':
      proxy_local_net_ip => $controller_pub_host,
      # it is not a mistake that proxy-logging is listed twice below.
      # for more on that, see
      # /usr/share/doc/openstack-swift-proxy-1.9.1/proxy-server.conf-sample
      pipeline           => [
        'healthcheck',
        'cache',
        'proxy-logging',
        'authtoken',
        'keystone',
        'proxy-logging',
        'proxy-server'
      ],
      account_autocreate => true,
      log_facility => 'LOG_LOCAL1',
    }

    # this declaration is needed so that the pipeline loop in
    # puppet-swift/manaifests/proxy.pp doesn't break.  note that
    # it ends up including the real logging class, proxy_logging
    class { '::swift::proxy::proxy-logging': }

    # configure all of the middlewares
    class { [
        '::swift::proxy::catch_errors',
        '::swift::proxy::healthcheck',
        '::swift::proxy::cache',
    ]: }

    class { '::swift::proxy::ratelimit':
        clock_accuracy         => 1000,
        max_sleep_time_seconds => 60,
        log_sleep_time_seconds => 0,
        rate_buffer_seconds    => 5,
        account_ratelimit      => 0
    }

    class { '::swift::proxy::keystone':
        operator_roles => ['admin', 'SwiftOperator'],
    }

    class { '::swift::proxy::authtoken':
        admin_user        => 'swift',
        admin_tenant_name => 'services',
        admin_password    => $swift_admin_password,
        # assume that the controller host is the swift api server
        auth_host         => $controller_pub_host,
    }

    class {'quickstack::swift::common':
      swift_shared_secret => $swift_shared_secret,
    }

    firewall { '001 swift proxy incoming':
        proto    => 'tcp',
        dport    => ['8080'],
        action   => 'accept',
    }

    if str2bool_i("$swift_is_ringserver") {

      # purposely using swift::ringbuilder::create, not
      # swift::ringbuilder since plain-old swift::ringbuilder does
      # things like rebalance the rings which we are taking care of in
      # swift_ring_build_helper.

      swift::ringbuilder::create{ ['object', 'account', 'container']:
        part_power     => '18',
        replicas       => '3',
        min_part_hours => '1',
	require        => Class['quickstack::swift::common'],
      }
      ->
      swift_ring_build_helper { "build the swift rings":
        ensure => "present",
        swift_storage_ips => $swift_storage_ips,
	swift_storage_device => $swift_storage_device,
      }

      # the following two rsync:: declarations are practically the
      # entire contents of swift::ringserver, but trying to use it
      # will give you dependency woes.  the short answer as to why is
      # because we need to use our own swift_ring_build_helper rather
      # than declare swift::ringbuilder which is required by
      # swift::ringserver.
      class { 'rsync::server':
          use_xinetd => true,
          address => $swift_ringserver_ip,
          use_chroot => 'no',
        }

      rsync::server::module { 'swift_server':
        path => '/etc/swift',
        lock_file => '/var/lock/swift_server.lock',
        uid => 'swift',
        gid => 'swift',
        max_connections => 5,
        read_only => true,
      }
    } else {

      swift::ringsync{["account","container","object"]:
        ring_server => $swift_ringserver_ip,
        before => Class['swift::proxy'],
        require => Class['swift'],
      }
      if ($::selinux != "false"){
          selboolean{'rsync_client':
              value => on,
              persistent => true,
          }
      }
    }
}
