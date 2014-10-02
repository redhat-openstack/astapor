# Quickstack Monitoring client
class quickstack::monitoring::client (
  $monitoring,
  $monitoring_host,
  $monitoring_interface,
) {
  case $monitoring {
    'nagios': {
      class {'nagios::client':
        monitored_ip       => getvar("ipaddress_${monitoring_interface}"),
        nagios_server_host => $monitoring_host,
      }

      firewall {'001 Nagios NRPE incoming':
        proto  => 'tcp',
        dport  => '5666',
        action => 'accept',
      }
    }
  }
}
