class quickstack::neutron::controller (
  $admin_email                  = $quickstack::params::admin_email,
  $admin_password               = $quickstack::params::admin_password,
  $ceilometer_metering_secret   = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password     = $quickstack::params::ceilometer_user_password,
  $heat_user_password           = $quickstack::params::heat_user_password,
  $heat_db_password             = $quickstack::params::heat_db_password,
  $cinder_db_password           = $quickstack::params::cinder_db_password,
  $cinder_user_password         = $quickstack::params::cinder_user_password,
  $glance_db_password           = $quickstack::params::glance_db_password,
  $glance_user_password         = $quickstack::params::glance_user_password,
  $horizon_secret_key           = $quickstack::params::horizon_secret_key,
  $keystone_admin_token         = $quickstack::params::keystone_admin_token,
  $keystone_db_password         = $quickstack::params::keystone_db_password,
  $metadata_proxy_shared_secret = $quickstack::params::metadata_proxy_shared_secret,
  $mysql_root_password          = $quickstack::params::mysql_root_password,
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $neutron_user_password        = $quickstack::params::neutron_user_password,
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $controller_priv_floating_ip  = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip   = $quickstack::params::controller_pub_floating_ip,
  $verbose                      = $quickstack::params::verbose
) inherits quickstack::params {

    class {'openstack::db::mysql':
        mysql_root_password  => $mysql_root_password,
        keystone_db_password => $keystone_db_password,
        glance_db_password   => $glance_db_password,
        nova_db_password     => $nova_db_password,
        cinder_db_password   => $cinder_db_password,
        neutron_db_password  => $neutron_db_password,

        # MySQL
        mysql_bind_address     => '0.0.0.0',
        mysql_account_security => true,

        # neutron
        neutron                => true,

        allowed_hosts          => ['%',$controller_priv_floating_ip],
        enabled                => true,
    }

    class {'qpid::server':
        auth => "no"
    }

    class {'openstack::keystone':
        db_host               => $controller_priv_floating_ip,
        db_password           => $keystone_db_password,
        admin_token           => $keystone_admin_token,
        admin_email           => $admin_email,
        admin_password        => $admin_password,
        glance_user_password  => $glance_user_password,
        nova_user_password    => $nova_user_password,
        cinder_user_password  => $cinder_user_password,
        neutron_user_password => $neutron_user_password,
        public_address        => $controller_pub_floating_ip,
        admin_address         => $controller_priv_floating_ip,
        internal_address      => $controller_priv_floating_ip,
        neutron               => false,
        enabled               => true,
        require               => Class['openstack::db::mysql'],
    }

    class { 'swift::keystone::auth':
        password => $swift_admin_password,
        address  => $controller_priv_floating_ip,
    }

    class { 'ceilometer::keystone::auth':
        password => $ceilometer_user_password,
        public_address => $controller_priv_floating_ip,
        admin_address => $controller_priv_floating_ip,
        internal_address => $controller_priv_floating_ip,
    }

    class {"heat::keystone::auth":
        password => $heat_user_password,
        heat_public_address => $controller_priv_floating_ip,
        heat_admin_address => $controller_priv_floating_ip,
        heat_internal_address => $controller_priv_floating_ip,
        cfn_auth_name => undef,
    }

    class {'openstack::glance':
        db_host        => $controller_priv_floating_ip,
        user_password  => $glance_user_password,
        db_password    => $glance_db_password,
        require        => Class['openstack::db::mysql'],
    }

    # Configure Nova
    class { 'nova':
        sql_connection     => "mysql://nova:${nova_db_password}@${controller_priv_floating_ip}/nova",
        image_service      => 'nova.image.glance.GlanceImageService',
        glance_api_servers => "http://${controller_priv_floating_ip}:9292/v1",
        rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
        verbose            => $verbose,
        require            => Class['openstack::db::mysql', 'qpid::server'],
    }

    class { 'nova::api':
        enabled           => true,
        admin_password    => $nova_user_password,
        auth_host         => $controller_priv_floating_ip,
        neutron_metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
    }

    nova_config {
        'DEFAULT/auto_assign_floating_ip': value => 'True';
        'DEFAULT/multi_host':              value => 'True';
        'DEFAULT/force_dhcp_release':      value => 'False';

        'keystone_authtoken/admin_tenant_name': value => 'admin';
        'keystone_authtoken/admin_user':        value => 'admin';
        'keystone_authtoken/admin_password':    value => $admin_password;
        'keystone_authtoken/auth_host':         value => '127.0.0.1';  
    }

    class { [ 'nova::scheduler', 'nova::cert', 'nova::consoleauth', 'nova::conductor' ]:
        enabled => true,
    }

    class { 'nova::vncproxy':
        host    => '0.0.0.0',
        enabled => true,
    }

    # Configure Ceilometer
    class { 'mongodb':
       enable_10gen => false,
       port         => '27017',
    }

    class { 'ceilometer':
        metering_secret => $ceilometer_metering_secret,
        qpid_hostname   => $controller_priv_floating_ip,
        rpc_backend     => 'ceilometer.openstack.common.rpc.impl_qpid',
        verbose         => $verbose,
    }

    class { 'ceilometer::db':
        database_connection => 'mongodb://localhost:27017/ceilometer',
        require             => Class['mongodb'],
    }

    class { 'ceilometer::collector':
        require => Class['ceilometer::db'],
    }

    class { 'ceilometer::agent::central':
        auth_url      => "http://${controller_priv_floating_ip}:35357/v2.0",
        auth_password => $ceilometer_user_password,
    }

    class { 'ceilometer::api':
        keystone_host     => $controller_priv_floating_ip,
        keystone_password => $ceilometer_user_password,
        require           => Class['mongodb'],
    }

    class { 'heat':
        keystone_host     => $controller_priv_floating_ip,
        keystone_password => $heat_user_password,
        auth_uri          => "http://${controller_priv_floating_ip}:35357/v2.0",
        rpc_backend       => 'heat.openstack.common.rpc.impl_qpid',
        qpid_hostname     => $controller_priv_floating_ip,
        verbose           => $verbose,
    }

    class {'heat::db::mysql':
        password => $heat_db_password,
        allowed_hosts => "%%",
    }

    class {'heat::db':
       sql_connection => "mysql://heat:${heat_db_password}@${controller_floating_ip}/heat"
    }

    class {'heat::api':
    }

    class {'heat::engine':
        heat_metadata_server_url      => "http://${controller_priv_floating_ip}:8000",
        heat_waitcondition_server_url => "http://${controller_priv_floating_ip}:8000/v1/waitcondition",
        heat_watch_server_url         => "http://${controller_priv_floating_ip}:8003",
    }

    glance_api_config {
        'DEFAULT/notifier_strategy': value => 'qpid'
    }

    class { 'quickstack::cinder_controller':
      cinder_db_password          => $cinder_db_password,
      cinder_user_password        => $cinder_user_password,
      controller_priv_floating_ip => $controller_priv_floating_ip,
      verbose                     => $verbose,
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
    }

    class {'memcached':}

    class { '::neutron':
        enabled               => true,
        verbose               => true,
        allow_overlapping_ips => true,
        rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
        qpid_hostname         => $controller_priv_floating_ip,
    }

    neutron_config {
        'database/connection': value => "mysql://neutron:${neutron_db_password}@${controller_priv_floating_ip}/neutron";
    }

    class { '::neutron::keystone::auth':
        password         => $admin_password,
        public_address   => $controller_pub_floating_ip,
        admin_address    => $controller_priv_floating_ip,
        internal_address => $controller_priv_floating_ip,
    }

    class { '::neutron::server':
        auth_host        => $::ipaddress,
        auth_password    => $admin_password,
     }

    neutron_plugin_ovs {
        'OVS/enable_tunneling': value => 'True';

        'SECURITYGROUP/firewall_driver':
        value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
    }

    class { '::neutron::plugins::ovs':
        sql_connection      => "mysql://neutron:${neutron_db_password}@${controller_priv_floating_ip}/neutron",
        tenant_network_type => 'gre',
    }

    class { '::nova::network::neutron':
        neutron_admin_password    => $neutron_user_password,
    }

    class { 'quickstack::neutron::network_public': }

    firewall { '001 controller incoming':
        proto    => 'tcp',
        dport    => ['80', '443', '3260', '3306', '5000', '35357', '5672', '8773', '8774', '8775', '8776', '9292', '6080', '9696'],   
        action   => 'accept',
    }

    if ($::selinux != "false"){
      selboolean { 'httpd_can_network_connect':
          value => on,
          persistent => true,
      }
    }
}
