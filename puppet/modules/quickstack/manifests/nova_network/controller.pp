# TODO
# refine iptable rules, their probably giving access to the public
#

class quickstack::nova_network::controller (
  $admin_email                 = $quickstack::params::admin_email,
  $admin_password              = $quickstack::params::admin_password,
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $heat_cfn                    = $quickstack::params::heat_cfn,
  $heat_cloudwatch             = $quickstack::params::heat_cloudwatch,
  $heat_user_password          = $quickstack::params::heat_user_password,
  $heat_db_password            = $quickstack::params::heat_db_password,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $cinder_user_password        = $quickstack::params::cinder_user_password,
  $glance_db_password          = $quickstack::params::glance_db_password,
  $glance_user_password        = $quickstack::params::glance_user_password,
  $horizon_secret_key          = $quickstack::params::horizon_secret_key,
  $keystone_admin_token        = $quickstack::params::keystone_admin_token,
  $keystone_db_password        = $quickstack::params::keystone_db_password,
  $mysql_root_password         = $quickstack::params::mysql_root_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $controller_priv_floating_ip = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip  = $quickstack::params::controller_pub_floating_ip,
  $mysql_host                  = $quickstack::params::mysql_host,
  $qpid_host                   = $quickstack::params::qpid_host,
  $verbose                     = $quickstack::params::verbose,
  $ssl                         = $quickstack::params::ssl,
  $freeipa                     = $quickstack::params::freeipa,
  $mysql_ca                    = $quickstack::params::mysql_ca,
  $mysql_cert                  = $quickstack::params::mysql_cert,
  $mysql_key                   = $quickstack::params::mysql_key,
  $qpid_ca                     = $quickstack::params::qpid_ca,
  $qpid_cert                   = $quickstack::params::qpid_cert,
  $qpid_key                    = $quickstack::params::qpid_key,
  $horizon_ca                  = $quickstack::params::horizon_ca,
  $horizon_cert                = $quickstack::params::horizon_cert,
  $horizon_key                 = $quickstack::params::horizon_key,
  $qpid_nssdb_password         = $quickstack::params::qpid_nssdb_password,
) inherits quickstack::params {

    #controller::corosync { 'quickstack': }

    #controller::corosync::node { '10.100.0.2': }
    #controller::corosync::node { '10.100.0.3': }

    #controller::resources::ip { '8.21.28.222':
    #    address => '8.21.28.222',
    #}
    #controller::resources::ip { '10.100.0.222':
    #    address => '10.100.0.222',
    #}

    #controller::resources::lsb { 'qpidd': }

    #controller::stonith::ipmilan { $ipmi_address:
    #    address  => $ipmi_address,
    #    user     => $ipmi_user,
    #    password => $ipmi_pass,
    #    hostlist => $ipmi_host_list,
    #}

    if str2bool($ssl) == true {
      $qpid_protocol = 'ssl'
      $qpid_port = '5671'
      $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_host}/nova?ssl_ca=${mysql_ca}"

      if str2bool($freeipa) == true {
        certmonger::request_ipa_cert { 'mysql':
          seclib => "openssl",
          principal => "mysql/${controller_priv_floating_ip}",
          key => $mysql_key,
          cert => $mysql_cert,
          owner_id => 'mysql',
          group_id => 'mysql',
        }
        certmonger::request_ipa_cert { 'horizon':
          seclib => "openssl",
          principal => "horizon/${controller_pub_floating_ip}",
          key => $horizon_key,
          cert => $horizon_cert,
          owner_id => 'apache',
          group_id => 'apache',
          hostname => $controller_pub_floating_ip,
        }
      } else {
        if $mysql_ca == undef or $mysql_cert == undef or $mysql_key == undef {
          fail('The mysql CA, cert and key are all required.')
        }
        if $qpid_ca == undef or $qpid_cert == undef or $qpid_key == undef {
          fail('The qpid CA, cert and key are all required.')
        }
        if $horizon_ca == undef or $horizon_cert == undef or
           $horizon_key == undef {
          fail('The horizon CA, cert and key are all required.')
        }
      }
    } else {
        $qpid_protocol = 'tcp'
        $qpid_port = '5672'
        $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_host}/nova"
    }


    class {'openstack::db::mysql':
        mysql_root_password  => $mysql_root_password,
        keystone_db_password => $keystone_db_password,
        glance_db_password   => $glance_db_password,
        nova_db_password     => $nova_db_password,
        cinder_db_password   => $cinder_db_password,
        neutron_db_password  => '',

        # MySQL
        mysql_bind_address     => '0.0.0.0',
        mysql_account_security => true,
        mysql_ssl              => str2bool($ssl),
        mysql_ca               => $mysql_ca,
        mysql_cert             => $mysql_cert,
        mysql_key              => $mysql_key,

        # neutron
        neutron                => false,

        allowed_hosts          => '%',
        enabled                => true,
    }

    class {'qpid::server':
        auth => "no",
        ssl      => str2bool($ssl),
        freeipa  => str2bool($freeipa),
        ssl_ca   => $qpid_ca,
        ssl_cert => $qpid_cert,
        ssl_key  => $qpid_key,
        ssl_database_password => $qpid_nssdb_password
    }

    class {'openstack::keystone':
        db_host                 => $mysql_host,
        db_password             => $keystone_db_password,
        db_ssl                  => str2bool($ssl),
        db_ssl_ca               => $mysql_ca,
        admin_token             => $keystone_admin_token,
        admin_email             => $admin_email,
        admin_password          => $admin_password,
        glance_user_password    => $glance_user_password,
        nova_user_password      => $nova_user_password,
        cinder_user_password    => $cinder_user_password,
        neutron_user_password   => "",

        public_address          => $controller_pub_floating_ip,
        admin_address           => $controller_priv_floating_ip,
        internal_address        => $controller_priv_floating_ip,

        glance_public_address   => $controller_pub_floating_ip,
        glance_admin_address    => $controller_priv_floating_ip,
        glance_internal_address => $controller_priv_floating_ip,

        nova_public_address     => $controller_pub_floating_ip,
        nova_admin_address      => $controller_priv_floating_ip,
        nova_internal_address   => $controller_priv_floating_ip,

        cinder_public_address   => $controller_pub_floating_ip,
        cinder_admin_address    => $controller_priv_floating_ip,
        cinder_internal_address => $controller_priv_floating_ip,

        neutron                 => false,
        enabled                 => true,
        require                 => Class['openstack::db::mysql'],
    }

    class { 'swift::keystone::auth':
        password         => $swift_admin_password,
        public_address   => $controller_pub_floating_ip,
        internal_address => $controller_priv_floating_ip,
        admin_address    => $controller_priv_floating_ip,
    }

    class {'openstack::glance':
        db_host       => $mysql_host,
        db_ssl        => str2bool($ssl),
        db_ssl_ca     => $mysql_ca,
        user_password => $glance_user_password,
        db_password   => $glance_db_password,
        require       => Class['openstack::db::mysql'],
    }

    class { 'quickstack::ceilometer_controller':
      ceilometer_metering_secret  => $ceilometer_metering_secret,
      ceilometer_user_password    => $ceilometer_user_password,
      controller_priv_floating_ip => $controller_priv_floating_ip,
      controller_pub_floating_ip  => $controller_pub_floating_ip,
      qpid_host                   => $qpid_host,
      qpid_protocol               => $qpid_protocol,
      qpid_port                   => $qpid_port,
      verbose                     => $verbose,
    }

    class { 'quickstack::cinder_controller':
      cinder_db_password          => $cinder_db_password,
      cinder_user_password        => $cinder_user_password,
      controller_priv_floating_ip => $controller_priv_floating_ip,
      mysql_host                  => $mysql_host,
      qpid_host                   => $qpid_host,
      verbose                     => $verbose,
    }

    class { 'quickstack::heat_controller':
      heat_cfn                    => $heat_cfn,
      heat_cloudwatch             => $heat_cloudwatch,
      heat_user_password          => $heat_user_password,
      heat_db_password            => $heat_db_password,
      controller_priv_floating_ip => $controller_priv_floating_ip,
      controller_pub_floating_ip  => $controller_pub_floating_ip,
      mysql_host                  => $mysql_host,
      qpid_host                   => $qpid_host,
      verbose                     => $verbose,
    }

    # Configure Nova
    class { 'nova':
        sql_connection     => $nova_sql_connection,
        image_service      => 'nova.image.glance.GlanceImageService',
        glance_api_servers => "http://${controller_priv_floating_ip}:9292/v1",
        rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
        verbose            => $verbose,
        qpid_protocol      => $qpid_protocol,
        qpid_port          => $qpid_port,
        qpid_hostname      => $controller_priv_floating_ip,
        require            => Class['openstack::db::mysql', 'qpid::server'],
    }

    class { 'nova::api':
        enabled           => true,
        admin_password    => $nova_user_password,
        auth_host         => $controller_priv_floating_ip,
    }

    nova_config {
        'DEFAULT/auto_assign_floating_ip': value => 'True';
        'DEFAULT/multi_host':              value => 'True';
        'DEFAULT/force_dhcp_release':      value => 'False';
    }

    class { [ 'nova::scheduler', 'nova::cert', 'nova::consoleauth', 'nova::conductor' ]:
        enabled => true,
    }

    class { 'nova::vncproxy':
        host    => '0.0.0.0',
        enabled => true,
    }

    package {'horizon-packages':
        name   => ['python-memcached', 'python-netaddr'],
        notify => Class['horizon'],
    }

    file {'/etc/httpd/conf.d/rootredirect.conf':
        ensure  => present,
        content => 'RedirectMatch ^/$ /dashboard/',
        notify  => File['/etc/httpd/conf.d/openstack-dashboard.conf'],
    }

    class {'horizon':
        secret_key    => $horizon_secret_key,
        keystone_host => $controller_priv_floating_ip,
        listen_ssl    => str2bool($ssl),
        horizon_cert  => $horizon_cert,
        horizon_key   => $horizon_key,
        horizon_ca    => $horizon_ca,
    }

    class {'memcached':}

# Double definition - This seems to have appeared with Puppet 3.x
#   class {'apache':}
#   class {'apache::mod::wsgi':}
#   file { '/etc/httpd/conf.d/openstack-dashboard.conf':}

    firewall { '001 controller incoming':
        proto    => 'tcp',
        # need to refine this list
        dport    => ['80', '3306', '5000', '35357', '5672', '8773', '8774', '8775', '8776', '9292', '6080'],
        action   => 'accept',
    }

    if $ssl {
        firewall { '002 ssl controller incoming':
            proto    => 'tcp',
            dport    => ['443',],
            action   => 'accept',
        }
    }

    if ($::selinux != "false"){
      selboolean{'httpd_can_network_connect':
          value => on,
          persistent => true,
      }
    }
}
