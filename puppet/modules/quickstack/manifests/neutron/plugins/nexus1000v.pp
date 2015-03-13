#
# Configure the Mech Driver for cisco nexus 1000v neutron plugin
#
# === Parameters
#
#[*n1kv_vsm_ip*]
#IP(s) of N1KV VSM(Virtual Supervisor Module)
#$n1kv_vsm_ip = 1.2.3.4, 5.6.7.8
#Defaults to empty
#
#[*n1kv_vsm_password*]
#Password of N1KV VSM(Virtual Supervisor Module)
#Defaults to empty
#
#[*n1kv_vsm_username*]
#Username of N1KV VSM(Virtual Supervisor Module)
#Defaults to empty
#
#[*default_policy_profile*]
# (Optional) Name of the policy profile to be associated with a port when no
# policy profile is specified during port creates.
# Default value:default-pp
# default_policy_profile = default-pp
#
#[*default_vlan_network_profile*]
# (Optional) Name of the VLAN network profile to be associated with a network.
# Default value:default-vlan-np
# default_vlan_network_profile = default-vlan-np
#
#[*default_vxlan_network_profile*]
# (Optional) Name of the VXLAN network profile to be associated with a network.
# Default value:default-vxlan-np
# default_vxlan_network_profile = default-vxlan-np
#
#[*poll_duration*]
# (Optional) Time in seconds for which the plugin polls the VSM for updates in
# policy profiles.
# Default value: 60
# poll_duration = 60
#
#[*http_pool_size*]
# (Optional) Number of threads to use to make HTTP requests to the VSM.
# Default value: 4
# http_pool_size = 4
#
#[*http_timeout*]
# (Optional) Timeout duration in seconds for the http request
# Default value: 15
# http_timeout = 15
#
#[*restrict_policy_profiles*]
# (Optional) Specify whether tenants are restricted from accessing all the
# policy profiles.
# Default value: False, indicating all tenants can access all policy profiles.
# restrict_policy_profiles = False
#
#[*enable_vif_type_n1kv*]
# (Optional) If set to True, the VIF type for portbindings is set to N1KV.
# Otherwise the VIF type is set to OVS.
# Default value: False, indicating that the VIF type will be set to OVS.
# enable_vif_type_n1kv = False
#
class quickstack::neutron::plugins::nexus1000v (
  $default_policy_profile		= 'default-pp',
  $default_vlan_network_profile		= 'default-vlan-np',
  $default_vxlan_network_profile	= 'default-vxlan-np',
  $poll_duration			= '60',
  $http_pool_size			= '4',
  $http_timeout				= '15',
  $n1kv_vsm_ip                          = undef,
  $n1kv_vsm_password                    = undef,
  $n1kv_vsm_username                    = undef,
  $restrict_policy_profiles             = 'False',
  $enable_vif_type_n1kv                 = 'False',
)
{
  package { 'cisco-n1kv-ml2-driver':
    require  => Package['openstack-neutron'],
  }

  $extension_drivers  = "cisco_n1kv_ext"
  neutron_plugin_ml2 {
    'ml2/extension_drivers'                          : value => $extension_drivers;
    'ml2_cisco_n1kv/default_policy_profile'          : value => $default_policy_profile;
    'ml2_cisco_n1kv/default_vlan_network_profile'    : value => $default_vlan_network_profile;
    'ml2_cisco_n1kv/default_vxlan_network_profile'   : value => $default_vxlan_network_profile;
    'ml2_cisco_n1kv/poll_duration'                   : value => $poll_duration;
    'ml2_cisco_n1kv/http_pool_size'                  : value => $http_pool_size;
    'ml2_cisco_n1kv/http_timeout'                    : value => $http_timeout;
    'ml2_cisco_n1kv/restrict_policy_profiles'        : value => $restrict_policy_profiles;
    'ml2_cisco_n1kv/n1kv_vsm_ips'                    : value => $n1kv_vsm_ip;
    'ml2_cisco_n1kv/username'                        : value => $n1kv_vsm_username;
    'ml2_cisco_n1kv/password'                        : value => $n1kv_vsm_password;
    'ml2_cisco_n1kv/enable_vif_type_n1kv'            : value => $enable_vif_type_n1kv;
  }
}
