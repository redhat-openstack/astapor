#
# == Class: quickstack::neutron::server
#
# Configure neutron server (API)
#
class quickstack::neutron::server (
  $public_protocol = 'http',
) inherits quickstack::params {

  $url_ssl = url_ssl($ssl, $mysql_ca)
  $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_vip}/neutron${url_ssl}"

  class { 'neutron::keystone::auth':
    password         => $neutron_user_password,
    public_address   => $neutron_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $neutron_vip_admin,
    internal_address => $neutron_vip_internal,
    region           => $region,
  }

  class { '::neutron::server':
    auth_host            => $auth_host,
    auth_password        => $neutron_user_password,
    auth_tenant          => $auth_tenant,
    auth_user            => $auth_user,
    connection           => $sql_connection,
    database_max_retries => $database_max_retries,
    enabled              => opposite_state("$quickstack::params::pcs_setup_neutron"),
    manage_service       => opposite_state("$quickstack::params::pcs_setup_neutron"),
    require              => Class['neutron'],
  }
  ->
  # FIXME: This really should be handled by the neutron-puppet module, which has
  # a review request open right now: https://review.openstack.org/#/c/50162/
  # If and when that is merged (or similar), the below can be removed.
  exec { 'neutron-db-manage upgrade':
    command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
    path        => '/usr/bin',
    user        => 'neutron',
    logoutput   => 'on_failure',
    before      => Service['neutron-server'],
    require     => [Neutron_config['database/connection'], Neutron_config['DEFAULT/core_plugin']],
  }
  File['/etc/neutron/plugin.ini'] -> Exec['neutron-db-manage upgrade']

  class {'::quickstack::firewall::neutron':}

  class {'::quickstack::neutron::plugins::neutron_config':
    neutron_conf_additional_params => $neutron_conf_additional_params,
  }

  class {'::quickstack::neutron::plugins::nova_config':
    nova_conf_additional_params => $nova_conf_additional_params,
  }
}

