# Quickstack Monitoring Server
class quickstack::monitoring::server (
  $admin_password,
  $monitoring,
  $monitoring_adm_passwd,
  $controller_admin_host,
) {
  case $monitoring {
    'nagios': {
      class {'nagios::server':
        admin_password       => $monitoring_adm_passwd,
        openstack_adm_passwd => $admin_password,
        openstack_controller => $controller_admin_host,
      }

      firewall {'001 Nagios Server incoming':
        proto    => 'tcp',
        dport    => ['80'],
        action   => 'accept',
      }
    }
  }
}
