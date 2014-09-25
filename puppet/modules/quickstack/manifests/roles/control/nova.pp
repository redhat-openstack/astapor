#
class quickstack::roles::control::nova (
  $neutron_metadata_proxy_secret = '',
  $public_protocol = 'http',
  $verbose         = 'false',
) inherits quickstack::roles::params {

  $amqp_port = amqp_port(str2bool_i("$ssl"))
  $qpid_protocol = qpid_protocol(str2bool_i("$ssl"))
  $url_ssl = url_ssl($ssl, $mysql_ca)
  $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_vip}/nova${url_ssl}"

  class { 'nova::keystone::auth':
    password         => $nova_user_password,
    public_address   => $nova_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $nova_vip_admin,
    internal_address => $nova_vip_internal,
    region           => $region,
  }

  contain nova::keystone::auth

  # Nova Controller
  class { '::nova':
    sql_connection     => $nova_sql_connection,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "http://${glance_vip_internal}:9292/v1",
    rpc_backend        => amqp_backend('nova', $amqp_provider),
    qpid_hostname      => $amqp_vip,
    qpid_protocol      => $qpid_protocol,
    qpid_port          => $amqp_port,
    qpid_username      => $amqp_username,
    qpid_password      => $amqp_password,
    rabbit_host        => $amqp_vip,
    rabbit_port        => $amqp_port,
    rabbit_userid      => $amqp_username,
    rabbit_password    => $amqp_password,
    rabbit_use_ssl     => str2bool_i("$ssl"),
    verbose            => $verbose,
    require            => Class['quickstack::db::mysql', 'quickstack::amqp::server'],
  }

  class { '::nova::api':
    enabled           => true,
    admin_password    => $nova_user_password,
    auth_host         => $keystone_vip_internal,
    neutron_metadata_proxy_shared_secret => $neutron_metadata_proxy_secret,
  }

  class { [ '::nova::scheduler', '::nova::cert', '::nova::consoleauth', '::nova::conductor' ]:
    enabled => true,
  }

  class { '::nova::vncproxy':
    host    => '0.0.0.0',
    enabled => true,
  }

  class {'quickstack::firewall::nova':}


  # ToDO
  firewall { '001 nova volume incoming':
    proto    => 'tcp',
    dport    => '3260',
    action   => 'accept',
  }

  # ToDO
  firewall { '001 EC2 API incoming':
    proto    => 'tcp',
    dport    => '8773',
    action   => 'accept',
  }

}
