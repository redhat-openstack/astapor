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
  $n1kv_vsm_ip                  = $quickstack::params::n1kv_vsm_ip,
  $n1kv_vsm_password            = $quickstack::params::n1kv_vsm_password,
  $n1kv_source                  = $quickstack::params::n1kv_source,
  $mysql_host                   = $quickstack::params::mysql_host,
  $mysql_ca                     = $quickstack::params::mysql_ca,
  $enable_server                = true,
  $enable_ovs_agent             = false,
  $tenant_network_type          = 'vlan',
  $ssl                          = $quickstack::params::ssl,
  #these variables are required to configure horizon local_settings.py
  $controller_admin_host        = $quickstack::params::controller_admin_host,
  $horizon_secret_key           = $quickstack::params::horizon_secret_key,
  $horizon_ca                   = $quickstack::params::horizon_ca,
  $horizon_cert                 = $quickstack::params::horizon_cert,
  $horizon_key                  = $quickstack::params::horizon_key,
  $controller_priv_host         = $quickstack::params::controller_priv_host,
  $django_debug                 = $quickstack::params::django_debug,
  $help_url                     = $quickstack::params::help_url,
  $cache_server_ip              = $quickstack::params::cache_server_ip,
  $cache_server_port            = $quickstack::params::cache_server_port,
  $keystone_port                = $quickstack::params::keystone_port,
  $keystone_scheme              = $quickstack::params::keystone_scheme,
  $keystone_default_role        = $quickstack::params::keystone_default_role,
  $can_set_mount_point          = $quickstack::params::can_set_mount_point,
  $api_result_limit             = $quickstack::params::api_result_limit,
  $log_level                    = $quickstack::params::log_level,
  $horizon_app_links            = $quickstack::params::horizon_app_links,
  $controller_pub_host          = $quickstack::params::controller_pub_host,
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
    if inline_template("<%=n1kv_source.include?('ftp')%>") == "true" {
      package { 'yum-plugin-priorities':
        name      => 'yum-plugin-priorities',
        ensure    => "installed"
      }
      yumrepo { "cisco-os":
        baseurl   => $n1kv_source,
        descr     => "Internal repo for Foreman",
        enabled   => 1,
        priority  => 1,
        gpgcheck  => 1,
        gpgkey    => "${n1kv_source}/RPM-GPG-KEY",
      }
    }

    if inline_template("<%=n1kv_source.include?('file')%>") == "true" {
      package { 'yum-plugin-priorities':
        name      => 'yum-plugin-priorities',
        ensure    => "installed"
      }

      yumrepo { "cisco-os":
        baseurl   => $n1kv_source,
        descr     => "Internal repo for Foreman",
        enabled   => 1,
        priority  => 1,
        gpgcheck  => 0,
      }
    }

    class { '::neutron::plugins::cisco':
      database_user     => $neutron_db_user,
      database_pass     => $neutron_db_password,
      database_host     => $controller_priv_host,
      keystone_password => $admin_password,
      keystone_auth_url => "http://${controller_priv_host}:35357/v2.0/",
      vswitch_plugin    => $cisco_vswitch_plugin,
    }

    $listen_ssl        = str2bool_i("$ssl")
    $support_profile   = 'cisco'
    $secret_key        = $horizon_secret_key
    $keystone_host     = $controller_priv_host
    $fqdn              = ["$controller_pub_host", "$::fqdn", "$::hostname", 'localhost']
    file {'/usr/share/openstack-dashboard/openstack_dashboard/local/local_settings.py':
      content => template('/usr/share/openstack-puppet/modules/horizon/templates/local_settings.py.erb')
    } ~> Service['httpd']

    $disable_router    = 'False'
    Neutron_plugin_cisco<||> ->
    file {'/usr/share/openstack-dashboard/openstack_dashboard/enabled/_40_router.py':
      content => template('quickstack/_40_router.py.erb')
    } ~> Service['httpd']

    Neutron_plugin_cisco<||> ->
    file {'/etc/neutron/plugins/cisco/cisco_plugins.ini':
      content => template('quickstack/cisco_plugins.ini.erb')
    } ~> Service['neutron-server']

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

