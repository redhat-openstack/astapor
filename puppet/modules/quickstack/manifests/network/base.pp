#
# == Class: quickstack::neutron
#
# Configure neutron base
#
# === Parameters
#
class quickstack::network::base (
  $allow_overlapping_ips,
) inherits quickstack::network::params {

  $amqp_port = amqp_port(str2bool_i("$ssl"))
  $qpid_protocol = qpid_protocol(str2bool_i("$ssl"))
  $url_ssl = url_ssl($ssl, $mysql_ca)
  $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_vip}/neutron${url_ssl}"

  class { '::neutron':
    allow_overlapping_ips => str2bool_i("$allow_overlapping_ips"),
    bind_host             => $neutron_host_priv,
    core_plugin           => $neutron_core_plugin,
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
    rabbit_use_ssl        => $ssl,
    verbose               => $neutron_verbose,
    network_device_mtu    => $network_device_mtu,
  }
}
