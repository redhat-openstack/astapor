#
class quickstack::network::agents::metadata ()
) inherits quickstack::network::params {
  class { '::neutron::agents::metadata':
    auth_password  => $neutron_user_password,
    auth_url       => "http://${auth_host}:35357/v2.0",
    enabled        => opposite_state("$pcs_setup_neutron"),
    manage_service => opposite_state("$pcs_setup_neutron"),
    metadata_ip    => $neutron_vip_admin,
    shared_secret  => $neutron_metadata_proxy_secret,
  }
}
