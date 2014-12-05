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
  $api_result_limit             = $quickstack::params::api_result_limit,
  # cisco config
  $cisco_vswitch_plugin         = $quickstack::params::cisco_vswitch_plugin,
  $cisco_nexus_plugin           = $quickstack::params::cisco_nexus_plugin,
  $controller_priv_host         = $quickstack::params::controller_priv_host,
  $controller_admin_host        = $quickstack::params::controller_admin_host,
  $cache_server_ip              = $quickstack::params::cache_server_ip,
  $cache_server_port            = $quickstack::params::cache_server_port,
  $can_set_mount_point          = $quickstack::params::can_set_mount_point,
  $controller_pub_host          = $quickstack::params::controller_pub_host,
  $django_debug                 = $quickstack::params::django_debug,
  $enable_server                = true,
  $enable_ovs_agent             = false,
  $help_url                     = $quickstack::params::help_url,
  $horizon_secret_key           = $quickstack::params::horizon_secret_key,
  $horizon_ca                   = $quickstack::params::horizon_ca,
  $horizon_cert                 = $quickstack::params::horizon_cert,
  $horizon_key                  = $quickstack::params::horizon_key,
  $horizon_app_links            = $quickstack::params::horizon_app_links,
  $keystone_port                = $quickstack::params::keystone_port,
  $keystone_scheme              = $quickstack::params::keystone_scheme,
  $keystone_default_role        = $quickstack::params::keystone_default_role,
  $log_level                    = $quickstack::params::log_level,
  $mysql_host                   = $quickstack::params::mysql_host,
  $mysql_ca                     = $quickstack::params::mysql_ca,
  $n1kv_vsm_ip                  = $quickstack::params::n1kv_vsm_ip,
  $n1kv_vsm_password            = $quickstack::params::n1kv_vsm_password,
  $n1kv_plugin_additional_params = { default_policy_profile => 'default-pp',
                                     network_node_policy_profile => 'default-pp',
                                     poll_duration => '10',
                                     http_pool_size => '4',
                                     http_timeout => '120',
                                     firewall_driver => 'neutron.agent.firewall.NoopFirewallDriver',
                                     enable_sync_on_start => 'True'
                                     restrict_policy_profiles => 'False',
                                   },
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $neutron_user_password        = $quickstack::params::neutron_user_password,
  $nexus_config                 = $quickstack::params::nexus_config,
  $nexus_credentials            = $quickstack::params::nexus_credentials,
  $neutron_core_plugin          = '',
  $n1kv_os_ha                   = 'true',
  # ovs config
  $ovs_vlan_ranges              = $quickstack::params::ovs_vlan_ranges,
  $provider_vlan_auto_create    = $quickstack::params::provider_vlan_auto_create,
  $provider_vlan_auto_trunk     = $quickstack::params::provider_vlan_auto_trunk,
  $ssl                          = $quickstack::params::ssl,
  $security_group_api		= $quickstack::params::security_group_api,
  $tenant_network_type          = 'vlan',
) inherits quickstack::params {


  if str2bool_i("$ssl") {
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron?ssl_ca=${mysql_ca}"
  } else {
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron"
  }

  if $cisco_vswitch_plugin == 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2' {
    # vswitch plugin is ovs, setup the ovs plugin
    neutron_plugin_ovs {
      'SECURITYGROUP/firewall_driver':
      value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
    }

    class { '::neutron::plugins::ovs':
      sql_connection      => $sql_connection,
      tenant_network_type => $tenant_network_type,
      network_vlan_ranges => $ovs_vlan_ranges,
    }
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

  if $cisco_vswitch_plugin == 'neutron.plugins.cisco.n1kv.n1kv_neutron_plugin.N1kvNeutronPluginV2' {
    class { '::neutron::plugins::cisco':
      database_user     => $neutron_db_user,
      database_pass     => $neutron_db_password,
      database_host     => $controller_priv_host,
      keystone_password => $admin_password,
      keystone_auth_url => "http://${controller_priv_host}:35357/v2.0/",
      vswitch_plugin    => $cisco_vswitch_plugin,
    }

    if $n1kv_os_ha == 'false' {
      $listen_ssl                  = str2bool_i("$ssl")
      $neutron_defaults     	   = {'enable_lb' => false, 'enable_firewall' => false, 'enable_quotas' => true, 'enable_security_group' => true, 'enable_vpn' => false, 'profile_support' => 'None' }
      $neutron_options         	   = {'enable_lb' => true, 'enable_firewall' => true, 'enable_quotas' => false, 'enable_security_group' => false, 'enable_vpn' => true, 'profile_support' => 'cisco' }
      $secret_key                  = $horizon_secret_key
      $keystone_host               = $controller_priv_host
      $fqdn                        = ["$controller_pub_host", "$::fqdn", "$::hostname", 'localhost']
      $openstack_endpoint_type	   = undef
      $compress_offline		   = True
      $file_upload_temp_dir	   = '/tmp'
      $available_regions       	   = undef
      $hypervisor_options 	   = {'can_set_mount_point' => false, 'can_set_password' => true }
      $hypervisor_defaults 	   = {'can_set_mount_point' => $can_set_mount_point, 'can_set_password'  => false }
      file {'/usr/share/openstack-dashboard/openstack_dashboard/local/local_settings.py':
        content => template('/usr/share/openstack-puppet/modules/horizon/templates/local_settings.py.erb')
      } ~> Service['httpd']

      $disable_router    = 'False'
      Neutron_plugin_cisco<||> ->
      file {'/usr/share/openstack-dashboard/openstack_dashboard/enabled/_40_router.py':
        content => template('quickstack/_40_router.py.erb')
      } ~> Service['httpd']
    }

    $default_policy_profile      = $n1kv_plugin_additional_params[default_policy_profile]
    $network_node_policy_profile = $n1kv_plugin_additional_params[network_node_policy_profile]
    $poll_duration               = $n1kv_plugin_additional_params[poll_duration]
    $http_pool_size              = $n1kv_plugin_additional_params[http_pool_size]
    $http_timeout                = $n1kv_plugin_additional_params[http_timeout]
    $firewall_driver	 	 = $n1kv_plugin_additional_params[firewall_driver]
    $enable_sync_on_start 	 = $n1kv_plugin_additional_params[enable_sync_on_start]
    $restrict_policy_profiles    = $n1kv_plugin_additional_params[restrict_policy_profiles]

    Neutron_plugin_cisco<||> ->
    file {'/etc/neutron/plugins/cisco/cisco_plugins.ini':
      content => template('quickstack/cisco_plugins.ini.erb')
    } ~> Service['neutron-server']

    if (!defined(Package['neutron-plugin-ovs'])) {
      package { 'neutron-plugin-ovs':
        ensure => present,
        name   => $::neutron::params::ovs_server_package,
      }
    }

  } else {
    package { 'python-ncclient':
      ensure => installed,
    } ~> Service['neutron-server']

    Neutron_plugin_cisco<||> ->
    file {'/etc/neutron/plugins/cisco/cisco_plugins.ini':
      owner => 'root',
      group => 'root',
      content => template('quickstack/cisco_plugins.ini.erb')
    } ~> Service['neutron-server']

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

