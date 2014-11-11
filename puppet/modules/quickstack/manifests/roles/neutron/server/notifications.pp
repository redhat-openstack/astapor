
class quickstack::roles::neutron::server::notifications (
) inherits quickstack::roles::params {

  class { '::neutron::server::notifications':
    notify_nova_on_port_status_changes => true,
    notify_nova_on_port_data_changes   => true,
    nova_url                           => "http://${nova_vip_public}:8774/v2",
    nova_admin_auth_url                => "http://${nova_vip_internal}:35357/v2.0",
    nova_admin_username                => "nova",
    nova_admin_password                => "${nova_user_password}",
  }
}
