# NRPE class for Nagios server
class quickstack::monitor::nagios::server::nrpe {

  Nagios_command {
    target => '/etc/nagios/conf.d/commands.cfg',
  }

  Nagios_service {
    target => '/etc/nagios/conf.d/services.cfg',
  }

  nagios_command {'check_nrpe':
    # Passing parameters to nrpe: Allow grouping plugins requests
    # Needs "dont_blame_nrpe=1" in remote host nrpe.cfg file
    # Less secure unless using TCP wrapper
    # command_line => '/usr/lib64/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -w $ARG1$ -c $ARG2$ -p $ARG3$',
    command_line => '/usr/lib64/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$',
  }

  nagios_service {'check_disk-var':
    hostgroup_name        => 'openstack-node',
    service_description   => '/var Filesystem usage',
    check_command         => 'check_nrpe!check_disk_var',
    normal_check_interval => '5',
    use                   => 'generic-service',
  }

  nagios_service {'check_load':
    hostgroup_name        => 'openstack-node',
    service_description   => 'Load average',
    check_command         => 'check_nrpe!check_load',
    normal_check_interval => '5',
    use                   => 'generic-service',
  }
}
