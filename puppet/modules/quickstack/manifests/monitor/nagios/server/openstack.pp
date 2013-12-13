# Openstack class for Nagios server
class quickstack::monitor::nagios::server::openstack(
  $admin_password,
  $controller_ip,
  $nagios_group,
  $nagios_user,
  $neutron,
  $swift,
) {

  File {
    owner => $nagios_user,
    group => $nagios_group,
  }

  Nagios_command {
    target => '/etc/nagios/conf.d/commands.cfg',
  }

  Nagios_host {
    target => '/etc/nagios/conf.d/hosts.cfg'
  }

  Nagios_hostgroup {
    target => '/etc/nagios/conf.d/hostgroups.cfg'
  }

  Nagios_service {
    target => '/etc/nagios/conf.d/services.cfg',
  }

  define quickstack::monitor::nagios::server::service (
    $command_name,
    $content,
    $hostgroup_name,
    $hostgroup_desc,
    $package_name = undef,
    $service_desc,
  ) {
    if (empty(nagios_hostgroups_filter("${hostgroup_name}"))) {
      alert ('Service needs to be added to quickstack function openstack_services_enabled.rb')
    }

    if ($package_name) {
      package { "$package_name":
        ensure => present
      }
    }

    nagios_hostgroup {"${hostgroup_name}":
      alias => "${hostgroup_desc}"
    }

    file {"/usr/lib64/nagios/plugins/${command_name}":
     mode    => 755,
     seltype => 'nagios_unconfined_plugin_exec_t',
     content => "${content}",
    }

    nagios_command {"${command_name}":
      command_line => "/usr/lib64/nagios/plugins/${command_name}",
    }

    nagios_service {"${command_name}":
      hostgroup_name        => "${hostgroup_name}",
      service_description   => "${service_desc}",
      check_command         => "${command_name}",
      normal_check_interval => '5',
      use                   => 'generic-service',
    }
  }

  file {'/etc/nagios/keystonerc_admin':
    ensure  => 'present',
    mode    => 600,
    content => template('quickstack/keystonerc_admin.erb'),
  }

  # Nodes
  nagios_hostgroup {'openstack-node':
    alias => 'Openstack Node',
  }

  # Services
  quickstack::monitor::nagios::server::service {'keystone':
    hostgroup_name => 'openstack-keystone',
    hostgroup_desc => 'OpenStack Keystone',
    package_name   => 'python-keystoneclient',
    command_name   => 'keystone-user-list',
    content        => template('quickstack/keystone-user-list.erb'),
    service_desc   => 'Number of keystone users',
  }

  quickstack::monitor::nagios::server::service {'nova-api':
    hostgroup_name => 'openstack-nova-api',
    hostgroup_desc => 'OpenStack Nova API',
    package_name   => 'python-novaclient',
    command_name   => 'nova-list',
    content        => template('quickstack/nova-list.erb'),
    service_desc   => 'Number of nova instances',
  }

  quickstack::monitor::nagios::server::service {'nova-novncproxy':
    hostgroup_name => 'openstack-nova-novncproxy',
    hostgroup_desc => 'OpenStack Nova novncproxy',
    package_name   => 'nc',
    command_name   => 'nova-novncproxy-check',
    content        => template('quickstack/nova-novncproxy-check.erb'),
    service_desc   => 'Check Nova novncproxy is listening',
  }

  quickstack::monitor::nagios::server::service {'nova-compute':
    hostgroup_name => 'openstack-nova-compute',
    hostgroup_desc => 'OpenStack Nova Compute',
    command_name   => 'check_nrpe!virsh_nodeinfo',
    content        => '',
    service_desc   => 'Virsh nodeinfo',
  }

  quickstack::monitor::nagios::server::service {'ceilometer-api':
    hostgroup_name => 'openstack-ceilometer-api',
    hostgroup_desc => 'OpenStack Ceilometer API',
    package_name   => 'python-ceilometerclient',
    command_name   => 'ceilometer-list',
    content        => template('quickstack/ceilometer-list.erb'),
    service_desc   => 'Number of ceilometer objects',
  }

  quickstack::monitor::nagios::server::service {'nova-novncproxy':
    hostgroup_name => 'openstack-nova-novncproxy',
    hostgroup_desc => 'OpenStack Nova novncproxy',
    package_name   => 'nc',
    command_name   => 'nova-novncproxy-check',
    content        => template('quickstack/nova-novncproxy-check.erb'),
    service_desc   => 'Check Nova novncproxy is listening',
  }

  quickstack::monitor::nagios::server::service {'cinder-api':
    hostgroup_name => 'openstack-cinder-api',
    hostgroup_desc => 'OpenStack Cinder API',
    package_name   => 'python-cinderclient',
    command_name   => 'cinder-list',
    content        => template('quickstack/cinder-list.erb'),
    service_desc   => 'Number of cinder volumes',
  }

  quickstack::monitor::nagios::server::service {'glance-api':
    hostgroup_name => 'openstack-glance-api',
    hostgroup_desc => 'OpenStack Glance API',
    package_name   => 'python-glanceclient',
    command_name   => 'glance-list',
    content        => template('quickstack/glance-list.erb'),
    service_desc   => 'Number of glance images',
  }

  quickstack::monitor::nagios::server::service {'heat-api':
    hostgroup_name => 'openstack-heat-api',
    hostgroup_desc => 'OpenStack Heat API',
    package_name   => 'python-heatclient',
    command_name   => 'heat-list',
    content        => template('quickstack/heat-list.erb'),
    service_desc   => 'Number of heat objects',
  }

  if str2bool("$neutron") {
    quickstack::monitor::nagios::server::service {'neutron-server':
      hostgroup_name => 'neutron-server',
      hostgroup_desc => 'Neutron API',
      package_name   => 'python-neutronclient',
      command_name   => 'neutron-net-list',
      content        => template('quickstack/neutron-net-list.erb'),
      service_desc   => 'Number of neutron networks',
    }
  }

  if str2bool("$swift") {
    quickstack::monitor::nagios::server::service {'swift-api':
      hostgroup_name => 'openstack-swift-api',
      hostgroup_desc => 'OpenStack Swift API',
      package_name   => 'python-swiftclient',
      command_name   => 'swift-list',
      content        => template('quickstack/swift-list.erb'),
      service_desc   => 'Number of swift objects',
    }
  }

  # Collect Opentsack hosts
  Nagios_host <<| |>>
}
