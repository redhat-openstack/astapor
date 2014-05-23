# Quickstack nagios client example for any node
class quickstack::monitor::nagios::client::node (
  $nagios             = $quickstack::params::nagios,
  $nagios_local_iface = $quickstack::params::nagios_local_iface,
  $nagios_server_ip   = $quickstack::params::nagios_server_ip,
) inherits quickstack::params {

  if str2bool_i("$nagios"){
    class {'quickstack::monitor::nagios::client':
      host_ip          => getvar("ipaddress_${nagios_local_iface}"),
      nagios_server_ip => $nagios_server_ip,
    }
  }
}
