#
# == Class: quickstack::roles::neutron::server
#
# Role to configure neutron server (API)
#
# === Parameters
#
class quickstack::roles::neutron::server (
  $database_max_retries  = '10',
  $enabled               = 'true',
  $manage_service        = 'true',
  $neutron_auth_tenant   = 'services',
  $neutron_auth_user     = 'neutron',
  $public_protocol       = 'http',
) inherits quickstack::roles::params {

  $url_ssl = url_ssl($ssl, $mysql_ca)
  $db_connection = "mysql://neutron:${neutron_db_password}@${mysql_vip}/neutron${url_ssl}"

  class { 'neutron::keystone::auth':
    password         => $neutron_user_password,
    public_address   => $neutron_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $neutron_vip_admin,
    internal_address => $neutron_vip_internal,
    region           => $region,
  }

  class { '::neutron::server':
    auth_host            => $keystone_vip_admin,
    auth_password        => $neutron_user_password,
    auth_tenant          => $neutron_auth_tenant,
    auth_user            => $neutron_auth_user,
    database_connection  => $db_connection,
    database_max_retries => $database_max_retries,
    enabled              => str2bool_i("$enabled"),
    manage_service       => str2bool_i("$manage_service"),
  }

  class {'::quickstack::firewall::neutron':}

  #if $core_plugin == 'neutron.plugins.ml2.plugin.Ml2Plugin' {
  #  neutron_config {
  #    'DEFAULT/service_plugins':
  #      value => join(['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',]),
  #  }
  #}
}
