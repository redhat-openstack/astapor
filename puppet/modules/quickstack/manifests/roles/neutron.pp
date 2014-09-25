#
# == Class: quickstack::roles::neutron::node
#
# Role to configure any neutron node (compute node or neutron server node)
#
# === Parameters
#
class quickstack::roles::neutron (
  $allow_overlapping_ips,
  $service_plugins,
  $verbose                = 'false',
) inherits quickstack::roles::params {

  $amqp_port = amqp_port(str2bool_i("$ssl"))
  $qpid_protocol = qpid_protocol(str2bool_i("$ssl"))
  $url_ssl = url_ssl($ssl, $mysql_ca)

  # $nova_sql_connection = "mysql://nova:${nova_db_password}@${mysql_vip}/nova${url_ssl}"
  # $neutron_sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_vip}/neutron${url_ssl}"

 class { '::neutron':
    allow_overlapping_ips => str2bool_i("$allow_overlapping_ips"),
    bind_host             => $neutron_private_vip,
    core_plugin           => $neutron_core_plugin,
    enabled               => true,
    rpc_backend           => amqp_backend('neutron', $amqp_provider),
    qpid_hostname         => $amqp_vip,
    qpid_port             => $amqp_port,
    qpid_protocol         => $qpid_protocol,
    qpid_username         => $amqp_username,
    qpid_password         => $amqp_password,
    rabbit_host           => $amqp_vip,
    rabbit_port           => $amqp_port,
    rabbit_user           => $amqp_username,
    rabbit_password       => $amqp_password,
    rabbit_use_ssl        => str2bool_i("$ssl"),
    kombu_ssl_keyfile     => $amqp_key,
    kombu_ssl_certfile    => $amqp_cert,
    kombu_ssl_ca_certs    => $amqp_ca,
    verbose               => $verbose,
  }
}
