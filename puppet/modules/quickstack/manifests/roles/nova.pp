#
# == Class: quickstack::roles::nova
#
# Role to configure nova base
#
# === Parameters
#
class quickstack::roles::nova (
  $verbose                = 'false',
) inherits quickstack::roles::params {

  $amqp_port = amqp_port(str2bool_i("$ssl"))
  $qpid_protocol = qpid_protocol(str2bool_i("$ssl"))
  $url_ssl = url_ssl($ssl, $mysql_ca)
  $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_vip}/nova${url_ssl}"

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
}
