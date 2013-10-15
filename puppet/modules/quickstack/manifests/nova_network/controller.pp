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
  $controller_priv_fqdn        = $quickstack::params::controller_priv_fqdn,
  $controller_pub_fqdn         = $quickstack::params::controller_pub_fqdn,
  $mysql_host                  = $quickstack::params::mysql_host,
  $qpid_host                   = $quickstack::params::qpid_host,
  $verbose                     = $quickstack::params::verbose
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

        # neutron
        neutron                => false,

        allowed_hosts          => '%',
        enabled                => true,
    }

    class {'qpid::server':
        auth => "no"
    }

    class {'openstack::keystone':
        db_host                 => $mysql_host,
        db_password             => $keystone_db_password,
        admin_token             => $keystone_admin_token,
        admin_email             => $admin_email,
        admin_password          => $admin_password,
        glance_user_password    => $glance_user_password,
        nova_user_password      => $nova_user_password,
        cinder_user_password    => $cinder_user_password,
        neutron_user_password   => "",

        public_address          => $controller_pub_fqdn,
        admin_address           => $controller_priv_fqdn,
        internal_address        => $controller_priv_fqdn,

        glance_public_address   => $controller_pub_fqdn,
        glance_admin_address    => $controller_priv_fqdn,
        glance_internal_address => $controller_priv_fqdn,

        nova_public_address     => $controller_pub_fqdn,
        nova_admin_address      => $controller_priv_fqdn,
        nova_internal_address   => $controller_priv_fqdn,

        cinder_public_address   => $controller_pub_fqdn,
        cinder_admin_address    => $controller_priv_fqdn,
        cinder_internal_address => $controller_priv_fqdn,

        neutron                 => false,
        enabled                 => true,
        require                 => Class['openstack::db::mysql'],
    }

    class { 'swift::keystone::auth':
        password         => $swift_admin_password,
        public_address   => $controller_pub_fqdn,
        internal_address => $controller_priv_fqdn,
        admin_address    => $controller_priv_fqdn,
    }

    class {'openstack::glance':
        db_host       => $mysql_host,
        user_password => $glance_user_password,
        db_password   => $glance_db_password,
        require       => Class['openstack::db::mysql'],
    }

    class { 'quickstack::ceilometer_controller':
      ceilometer_metering_secret  => $ceilometer_metering_secret,
      ceilometer_user_password    => $ceilometer_user_password,
      controller_priv_fqdn        => $controller_priv_fqdn,
      controller_pub_fqdn         => $controller_pub_fqdn,
      qpid_host                   => $qpid_host,
      verbose                     => $verbose,
    }

    class { 'quickstack::cinder_controller':
      cinder_db_password          => $cinder_db_password,
      cinder_user_password        => $cinder_user_password,
      controller_priv_fqdn        => $controller_priv_fqdn,
      mysql_host                  => $mysql_host,
      qpid_host                   => $qpid_host,
      verbose                     => $verbose,
    }

    class { 'quickstack::heat_controller':
      heat_cfn                    => $heat_cfn,
      heat_cloudwatch             => $heat_cloudwatch,
      heat_user_password          => $heat_user_password,
      heat_db_password            => $heat_db_password,
      controller_priv_fqdn        => $controller_priv_fqdn,
      controller_pub_fqdn         => $controller_pub_fqdn,
      mysql_host                  => $mysql_host,
      qpid_host                   => $qpid_host,
      verbose                     => $verbose,
    }

    # Configure Nova
    class { 'nova':
        sql_connection     => "mysql://nova:${nova_db_password}@${mysql_host}/nova",
        image_service      => 'nova.image.glance.GlanceImageService',
        glance_api_servers => "http://${controller_priv_fqdn}:9292/v1",
        rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
        verbose            => $verbose,
        require            => Class['openstack::db::mysql', 'qpid::server'],
    }

    class { 'nova::api':
        enabled           => true,
        admin_password    => $nova_user_password,
        auth_host         => $controller_priv_fqdn,
    }

    nova_config {
        'DEFAULT/auto_assign_fqdn': value => 'True';
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
        keystone_host => $controller_priv_fqdn,
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

    if ($::selinux != "false"){
      selboolean{'httpd_can_network_connect':
          value => on,
          persistent => true,
      }
    }
}
