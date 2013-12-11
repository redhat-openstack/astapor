class quickstack::params {
  # Logs
  $admin_email                = "admin@${::domain}"
  $verbose                    = 'true'

  $heat_cfn                   = 'false'
  $heat_cloudwatch            = 'false'

  # Passwords are currently changed to decent strings by sed
  # during the setup process. This will move to the Foreman API v2
  # at some point.
  $admin_password             = 'CHANGEME'
  $ceilometer_metering_secret = 'CHANGEME'
  $ceilometer_user_password   = 'CHANGEME'
  $heat_user_password         = 'CHANGEME'
  $heat_db_password           = 'CHANGEME'
  $horizon_secret_key         = 'CHANGEME'
  $keystone_admin_token       = 'CHANGEME'
  $keystone_db_password       = 'CHANGEME'
  $mysql_root_password        = 'CHANGEME'
  $neutron_db_password        = 'CHANGEME'
  $neutron_user_password      = 'CHANGEME'
  $nova_db_password           = 'CHANGEME'
  $nova_user_password         = 'CHANGEME'

  # Cinder
  $cinder_db_password           = 'CHANGEME'
  $cinder_user_password         = 'CHANGEME'
  # Cinder backend - Several backends should be able to coexist
  $cinder_backend_gluster       = false
  $cinder_backend_iscsi         = false
  # Cinder gluster
  $cinder_gluster_volume        = 'cinder'
  $cinder_gluster_path          = '/srv/gluster/cinder'
  $cinder_gluster_peers         = [ '192.168.0.4', '192.168.0.5', '192.168.0.6' ]
  $cinder_gluster_replica_count = '3'

  # Glance
  $glance_db_password           = 'CHANGEME'
  $glance_user_password         = 'CHANGEME'
  # Glance_Gluster
  $glance_gluster_volume        = 'glance'
  $glance_gluster_path          = '/srv/gluster/glance'
  $glance_gluster_peers         = [ '192.168.0.4', '192.168.0.5', '192.168.0.6' ]
  $glance_gluster_replica_count = '3'

  # Networking
  $neutron                       = 'false'
  $private_interface             = 'PRIV_INTERFACE'
  $public_interface              = 'PUB_INTERFACE'
  $controller_priv_floating_ip   = 'PRIV_IP'
  $controller_pub_floating_ip    = 'PUB_IP'

  # Nova-network specific
  $fixed_network_range           = 'PRIV_RANGE'
  $floating_network_range        = 'PUB_RANGE'
  $auto_assign_floating_ip       = 'True'

  # Neutron specific
  $neutron_metadata_proxy_secret  = 'CHANGEME'

  $mysql_host                    = 'PRIV_IP'
  $qpid_host                     = 'PRIV_IP'
  $qpid_username                 = 'openstack'
  $qpid_password                 = 'CHANGEME'
  $bridge_interface              = 'PRIV_IP'
  $enable_ovs_agent              = 'true'
  $tenant_network_type           = 'gre'
  $ovs_vlan_ranges               = undef
  $ovs_bridge_mappings           = []
  $ovs_bridge_uplinks            = []
  $configure_ovswitch            = 'true'
  $enable_tunneling              = 'True'

  # neutron plugin config
  $neutron_core_plugin           = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2'
  # If using the Cisco plugin, use either OVS or n1k for virtualised l2
  $cisco_vswitch_plugin          = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2'
  # If using the Cisco plugin, Nexus hardware can be used for l2
  $cisco_nexus_plugin            = 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin'

  # If using the nexus sub plugin, specify the hardware layout by
  # using the following syntax:
  # $nexus_config = { 'SWITCH_IP' => { 'COMPUTE_NODE_NAME' : 'PORT' } }
  $nexus_config                  = undef

  # Set the nexus login credentials by creating a list
  # of switch_ip/username/password strings as per the example below:
  $nexus_credentials             = undef

  # provider network settings
  $provider_vlan_auto_create     = 'false'
  $provider_vlan_auto_trunk      = 'false'
  $mysql_virt_ip_nic             = 'PRIV_IP'
  $mysql_virt_ip_cidr_mask       = 'MYSQL_CIDR_MASK'
  $mysql_shared_storage_device   = 'MYSQL_SHARED_STORAGE_DEVICE'
  # e.g. "nfs"
  $mysql_shared_storage_type     = 'MYSQL_SHARED_STORAGE_TYPE'
  $mysql_clu_member_addrs        = 'SPACE_SEPARATED_IP_ADDRS'
  $mysql_resource_group_name     = 'mysqlgroup'
}
