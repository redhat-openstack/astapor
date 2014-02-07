# Quickstack controller node
class quickstack::controller_common (
  $admin_email                   = $quickstack::params::admin_email,
  $admin_password                = $quickstack::params::admin_password,
  $ceilometer_metering_secret    = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password      = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster        = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_iscsi          = $quickstack::params::cinder_backend_iscsi,
  $cinder_db_password            = $quickstack::params::cinder_db_password,
  $cinder_gluster_servers        = $quickstack::params::cinder_gluster_servers,
  $cinder_gluster_volume         = $quickstack::params::cinder_gluster_volume,
  $cinder_user_password          = $quickstack::params::cinder_user_password,
  $controller_admin_host         = $quickstack::params::controller_admin_host,
  $controller_priv_host          = $quickstack::params::controller_priv_host,
  $controller_pub_host           = $quickstack::params::controller_pub_host,
  $glance_db_password            = $quickstack::params::glance_db_password,
  $glance_user_password          = $quickstack::params::glance_user_password,
  $heat_cfn                      = $quickstack::params::heat_cfn,
  $heat_cloudwatch               = $quickstack::params::heat_cloudwatch,
  $heat_db_password              = $quickstack::params::heat_db_password,
  $heat_user_password            = $quickstack::params::heat_user_password,
  $horizon_secret_key            = $quickstack::params::horizon_secret_key,
  $keystone_admin_token          = $quickstack::params::keystone_admin_token,
  $keystone_db_password          = $quickstack::params::keystone_db_password,
  $neutron_metadata_proxy_secret = $quickstack::params::neutron_metadata_proxy_secret,
  $mysql_host                    = $quickstack::params::mysql_host,
  $mysql_root_password           = $quickstack::params::mysql_root_password,
  $neutron                       = $quickstack::params::neutron,
  $neutron_core_plugin           = $quickstack::params::neutron_core_plugin,
  $neutron_db_password           = $quickstack::params::neutron_db_password,
  $neutron_user_password         = $quickstack::params::neutron_user_password,
  $nova_db_password              = $quickstack::params::nova_db_password,
  $nova_user_password            = $quickstack::params::nova_user_password,
  $swift_shared_secret           = $quickstack::params::swift_shared_secret,
  $swift_admin_password          = $quickstack::params::swift_admin_password,
  $qpid_host                     = $quickstack::params::qpid_host,
  $verbose                       = $quickstack::params::verbose,
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

    allowed_hosts          => ['%',$controller_priv_host],
    enabled                => true,

    # Networking
    neutron                => str2bool_i("$neutron"),
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
    neutron_user_password   => $neutron_user_password,

    public_address          => $controller_pub_host,
    admin_address           => $controller_admin_host,
    internal_address        => $controller_priv_host,

    glance_public_address   => $controller_pub_host,
    glance_admin_address    => $controller_admin_host,
    glance_internal_address => $controller_priv_host,

    nova_public_address     => $controller_pub_host,
    nova_admin_address      => $controller_admin_host,
    nova_internal_address   => $controller_priv_host,

    cinder_public_address   => $controller_pub_host,
    cinder_admin_address    => $controller_admin_host,
    cinder_internal_address => $controller_priv_host,

    neutron_public_address   => $controller_pub_host,
    neutron_admin_address    => $controller_admin_host,
    neutron_internal_address => $controller_priv_host,

    neutron                 => str2bool_i("$neutron"),
    enabled                 => true,
    require                 => Class['openstack::db::mysql'],
  }

  class { 'swift::keystone::auth':
    password         => $swift_admin_password,
    public_address   => $controller_pub_host,
    internal_address => $controller_priv_host,
    admin_address    => $controller_admin_host
  }

  class {'openstack::glance':
    db_host        => $mysql_host,
    user_password  => $glance_user_password,
    db_password    => $glance_db_password,
    require        => Class['openstack::db::mysql'],
  }

  # Configure Nova
  class { 'nova':
    sql_connection     => "mysql://nova:${nova_db_password}@${mysql_host}/nova",
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "http://${controller_priv_host}:9292/v1",
    rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
    qpid_hostname      => $qpid_host,
    verbose            => $verbose,
    require            => Class['openstack::db::mysql', 'qpid::server'],
  }

  if str2bool_i("$neutron") {
    class { 'nova::api':
      enabled           => true,
      admin_password    => $nova_user_password,
      auth_host         => $controller_priv_host,
      neutron_metadata_proxy_shared_secret => $neutron_metadata_proxy_secret,
    }
  } else {
    class { 'nova::api':
      enabled           => true,
      admin_password    => $nova_user_password,
      auth_host         => $controller_priv_host,
    }
  }

  class { [ 'nova::scheduler', 'nova::cert', 'nova::consoleauth', 'nova::conductor' ]:
    enabled => true,
  }

  class { 'nova::vncproxy':
    host    => '0.0.0.0',
    enabled => true,
  }

  class { 'quickstack::ceilometer_controller':
    ceilometer_metering_secret  => $ceilometer_metering_secret,
    ceilometer_user_password    => $ceilometer_user_password,
    controller_admin_host       => $controller_admin_host,
    controller_priv_host        => $controller_priv_host,
    controller_pub_host         => $controller_pub_host,
    qpid_host                   => $qpid_host,
    verbose                     => $verbose,
  }

  class {'quickstack::swift::proxy':
    controller_pub_host        => $controller_pub_host,
    swift_admin_password       => $swift_admin_password,
    swift_shared_secret        => $swift_shared_secret,
  }

  class { 'quickstack::cinder_controller':
    cinder_backend_gluster      => $cinder_backend_gluster,
    cinder_backend_iscsi        => $cinder_backend_iscsi,
    cinder_db_password          => $cinder_db_password,
    cinder_gluster_volume       => $cinder_gluster_volume,
    cinder_gluster_servers      => $cinder_gluster_servers,
    cinder_user_password        => $cinder_user_password,
    controller_priv_host        => $controller_priv_host,
    mysql_host                  => $mysql_host,
    qpid_host                   => $qpid_host,
    verbose                     => $verbose,
  }

  class { 'quickstack::heat_controller':
    heat_cfn                    => $heat_cfn,
    heat_cloudwatch             => $heat_cloudwatch,
    heat_user_password          => $heat_user_password,
    heat_db_password            => $heat_db_password,
    controller_admin_host       => $controller_admin_host,
    controller_priv_host        => $controller_priv_host,
    controller_pub_host         => $controller_pub_host,
    mysql_host                  => $mysql_host,
    qpid_host                   => $qpid_host,
    verbose                     => $verbose,
  }

  # horizon packages
  package {'python-memcached':
    ensure => installed,
  }~>
  package {'python-netaddr':
    ensure => installed,
    notify => Class['horizon'],
  }

  file {'/etc/httpd/conf.d/rootredirect.conf':
    ensure  => present,
    content => 'RedirectMatch ^/$ /dashboard/',
    notify  => File['/etc/httpd/conf.d/openstack-dashboard.conf'],
  }

  class {'horizon':
    secret_key    => $horizon_secret_key,
    keystone_host => $controller_priv_host,
  }

  class {'memcached':}

  firewall { '001 controller incoming':
    proto    => 'tcp',
    dport    => ['80', '443', '3260', '3306', '5000', '35357', '5672', '8773', '8774', '8775', '8776', '8777', '9292', '6080'],
    action   => 'accept',
  }

  if ($::selinux != "false"){
    selboolean { 'httpd_can_network_connect':
      value => on,
      persistent => true,
    }
  }
}
