# Quickstart class for nova network controller
class quickstack::nova_network::controller () inherits quickstack::params {
   nova_config {
    'DEFAULT/auto_assign_floating_ip': value => 'True';
    'DEFAULT/multi_host':              value => 'True';
    'DEFAULT/force_dhcp_release':      value => 'False';
   }
}
