class quickstack::storage_backend::lvm_cinder(
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_iscsi        = $quickstack::params::cinder_backend_iscsi,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $cinder_gluster_volume       = $quickstack::params::cinder_gluster_volume,
  $cinder_gluster_peers        = $quickstack::params::cinder_gluster_peers,
  $controller_priv_host        = $quickstack::params::controller_priv_host,
  $cinder_iscsi_iface          = 'eth1',
  $cinder_iscsi_network        = '',
  $mysql_host                  = $quickstack::params::mysql_host,
  $ntp_servers                 = ['0.pool.ntp.org','1.pool.ntp.org','2.pool.ntp.org'],
  $qpid_host                   = $quickstack::params::qpid_host,
  $qpid_username               = $quickstack::params::qpid_username,
  $qpid_password               = $quickstack::params::qpid_password,
  $verbose                     = $quickstack::params::verbose,
  $ssl                         = $quickstack::params::ssl,
  $mysql_ca                    = $quickstack::params::mysql_ca,
) inherits quickstack::params {

  class {'quickstack::openstack_common':
    ntp_servers => $ntp_servers,
  }

  if str2bool_i("$ssl") {
    $qpid_protocol = 'ssl'
    $qpid_port = '5671'
    $sql_connection = "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder?ssl_ca=${mysql_ca}"
  } else {
    $qpid_protocol = 'tcp'
    $qpid_port = '5672'
    $sql_connection = "mysql://cinder:${cinder_db_password}@${mysql_host}/cinder"
  }
  class { '::cinder':
    rpc_backend    => 'cinder.openstack.common.rpc.impl_qpid',
    qpid_hostname  => $qpid_host,
    qpid_port      => $qpid_port,
    qpid_protocol  => $qpid_protocol,
    qpid_username  => $qpid_username,
    qpid_password  => $qpid_password,
    sql_connection => $sql_connection,
    verbose        => $verbose,
  }

  class { '::cinder::volume': }

  if str2bool_i("$cinder_backend_gluster") {
    class { 'gluster::client': }

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
