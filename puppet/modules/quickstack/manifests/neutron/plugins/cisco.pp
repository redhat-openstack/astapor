# Copyright 2013 Cisco Systems, Inc.  All rights reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
class quickstack::neutron::plugins::cisco (
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $neutron_user_password        = $quickstack::params::neutron_user_password,
  # ovs config
  $ovs_vlan_ranges              = $quickstack::params::ovs_vlan_ranges,
  # cisco config
  $cisco_vswitch_plugin         = $quickstack::params::cisco_vswitch_plugin,
  $nexus_config                 = $quickstack::params::nexus_config,
  $cisco_nexus_plugin           = $quickstack::params::cisco_nexus_plugin,
  $nexus_credentials            = $quickstack::params::nexus_credentials,
  $provider_vlan_auto_create    = $quickstack::params::provider_vlan_auto_create,
  $provider_vlan_auto_trunk     = $quickstack::params::provider_vlan_auto_trunk,
  $mysql_host                   = $quickstack::params::mysql_host,
  $mysql_ca                     = $quickstack::params::mysql_ca,
  $enable_server                = true,
  $enable_ovs_agent             = false,
  $tenant_network_type          = 'vlan',
  $ssl                          = $quickstack::params::ssl,
) inherits quickstack::params {


  if str2bool($ssl) {
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron?ssl_ca=${mysql_ca}"
  } else {
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron"
  }

  if $cisco_vswitch_plugin == 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2' {
    # vswitch plugin is ovs, setup the ovs plugin

    class { '::neutron::plugins::ovs':
      sql_connection      => $sql_connection,
      tenant_network_type => $tenant_network_type,
      network_vlan_ranges => $ovs_vlan_ranges,
    }
  }

  if $cisco_nexus_plugin == 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin' {
    # nexus plugin, setup necessary dependencies and config files"
    package { 'python-ncclient':
      ensure => installed,
    } ~> Service['neutron-server']

    Neutron_plugin_cisco<||> ->
    file {'/etc/neutron/plugins/cisco/cisco_plugins.ini':
      owner => 'root',
      group => 'root',
      content => template('quickstack/cisco_plugins.ini.erb')
    } ~> Service['neutron-server']
  }

  if $nexus_credentials {
    file {'/var/lib/neutron/.ssh':
      ensure => directory,
      owner  => 'neutron',
      require => Package['neutron']
    }
    nexus_creds{ $nexus_credentials:
      require => File['/var/lib/neutron/.ssh']
    }
  }
  
  class { '::neutron::plugins::cisco':
    database_user     => $neutron_db_user,
    database_pass     => $neutron_db_password,
    database_host     => $controller_priv_host,
    keystone_password => $admin_password,
    keystone_auth_url => "http://${controller_priv_host}:35357/v2.0/",
    vswitch_plugin    => $cisco_vswitch_plugin,
    nexus_plugin      => $cisco_nexus_plugin
  }

}

define nexus_creds {
  $args = split($title, '/')
  neutron_plugin_cisco_credentials {
    "${args[0]}/username": value => $args[1];
    "${args[0]}/password": value => $args[2];
  }
  exec {"${title}":
    unless => "/bin/cat /var/lib/neutron/.ssh/known_hosts | /bin/grep ${args[0]}",
    command => "/usr/bin/ssh-keyscan -t rsa ${args[0]} >> /var/lib/neutron/.ssh/known_hosts",
    user    => 'neutron',
    require => Package['neutron']
  }
}

