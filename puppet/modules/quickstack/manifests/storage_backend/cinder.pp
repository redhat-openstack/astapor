class quickstack::storage_backend::cinder(
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_iscsi        = $quickstack::params::cinder_backend_iscsi,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $cinder_gluster_volume       = $quickstack::params::cinder_gluster_volume,
  $cinder_gluster_peers        = $quickstack::params::cinder_gluster_peers,
  $controller_priv_host        = $quickstack::params::controller_priv_host,
  $cinder_iscsi_iface          = 'eth1',
  $cinder_iscsi_network        = '',
  $mysql_host                  = $quickstack::params::mysql_host,
  $amqp_server                 = $quickstack::params::amqp_server,
  $amqp_host                   = $quickstack::params::amqp_host,
  $amqp_username               = $quickstack::params::amqp_username,
  $amqp_password               = $quickstack::params::amqp_password,
  $verbose                     = $quickstack::params::verbose,
  $ssl                         = $quickstack::params::ssl,
  $mysql_ca                    = $quickstack::params::mysql_ca,
) inherits quickstack::params {

  class {'quickstack::openstack_common': }

  if str2bool_i("$ssl") {
    $qpid_protocol = 'ssl'
    $amqp_port = '5671'
    $sql_connection = "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder?ssl_ca=${mysql_ca}"
  } else {
    $qpid_protocol = 'tcp'
    $amqp_port = '5672'
    $sql_connection = "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder"
  }
  class { '::cinder':
    rpc_backend    => amqp_backend('cinder', $amqp_server),
    qpid_hostname  => $amqp_host,
    qpid_port      => $amqp_port,
    qpid_protocol  => $qpid_protocol,
    qpid_username  => $amqp_username,
    qpid_password  => $amqp_password,
    rabbit_host    => $amqp_host,
    rabbit_port    => $amqp_port,
    rabbit_userid  => $amqp_username,
    rabbit_password=> $amqp_password,
    sql_connection => $sql_connection,
    verbose        => $verbose,
  }

  class { '::cinder::volume': }

  if str2bool_i("$cinder_backend_gluster") {
    if defined('gluster::client') {
      class { 'gluster::client': }
    } else {
      class { 'puppet::vardir': }
      class { 'gluster::mount::base': repo => false }
    }

    if ($::selinux != "false") {
      selboolean{'virt_use_fusefs':
          value => on,
          persistent => true,
      }
    }

    class { '::cinder::volume::glusterfs':
      glusterfs_mount_point_base => '/var/lib/cinder/volumes',
      glusterfs_shares           => suffix($cinder_gluster_peers, ":/${cinder_gluster_volume}")
    }
  }

  if str2bool_i("$cinder_backend_iscsi") {
    $iscsi_ip_address = find_ip("$cinder_iscsi_network",
                                "$cinder_iscsi_iface",
                                "")
    class { '::cinder::volume::iscsi':
      iscsi_ip_address => $iscsi_ip_address,
    }

    firewall { '010 cinder iscsi':
      proto  => 'tcp',
      dport  => ['3260'],
      action => 'accept',
    }
  }
}
