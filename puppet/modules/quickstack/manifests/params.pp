class quickstack::params (
  $scenarii = [],
  $scenario = '',

  # Logs
  $admin_email                = "admin@${::domain}",
  $verbose                    = 'true',

  $heat_cfn                   = 'false',
  $heat_cloudwatch            = 'false',

  # Passwords are currently changed to decent strings by sed
  # during the setup process. This will move to the Foreman API v2
  # at some point.
  $admin_password             = 'CHANGEME',
  $ceilometer_metering_secret = 'CHANGEME',
  $ceilometer_user_password   = 'CHANGEME',
  $heat_user_password         = 'CHANGEME',
  $heat_db_password           = 'CHANGEME',
  $horizon_secret_key         = 'CHANGEME',
  $keystone_admin_token       = 'CHANGEME',
  $keystone_db_password       = 'CHANGEME',
  $mysql_root_password        = 'CHANGEME',
  $neutron_db_password        = 'CHANGEME',
  $neutron_user_password      = 'CHANGEME',
  $nova_db_password           = 'CHANGEME',
  $nova_user_password         = 'CHANGEME',

  # Cinder
  $cinder_db_password           = 'CHANGEME',
  $cinder_user_password         = 'CHANGEME',
  # Cinder backend - Several backends should be able to coexist
  $cinder_backend_gluster       = false,
  $cinder_backend_gluster_name  = 'glusterfs',
  $cinder_backend_iscsi         = false,
  $cinder_backend_iscsi_name    = 'iscsi',
  $cinder_backend_nfs           = false,
  $cinder_backend_nfs_name      = 'nfs',
  $cinder_backend_eqlx          = false,
  $cinder_backend_eqlx_name     = ['eqlx'],
  $cinder_backend_netapp        = false,
  $cinder_multiple_backends     = false,
  $cinder_backend_rbd           = false,
  $cinder_backend_rbd_name      = 'rbd',
  # Cinder gluster
  $cinder_gluster_volume        = 'cinder',
  $cinder_gluster_path          = '/srv/gluster/cinder',
  $cinder_gluster_peers         = [ '192.168.0.4', '192.168.0.5', '192.168.0.6' ],
  $cinder_gluster_replica_count = '3',
  $cinder_glusterfs_shares      = [ '192.168.0.4:/cinder -o backup-volfile-servers=192.168.0.5' ],
  # Cinder nfs
  $cinder_nfs_shares            = [ '192.168.0.4:/cinder' ],
  $cinder_nfs_mount_options     = '',
  # Cinder Dell EqualLogic
  $cinder_san_ip                = ['192.168.124.11'],
  $cinder_san_login             = ['grpadmin'],
  $cinder_san_password          = ['CHANGEME'],
  $cinder_san_thin_provision    = [true],
  $cinder_eqlx_group_name       = ['group-0'],
  $cinder_eqlx_pool             = ['default'],
  $cinder_eqlx_use_chap         = [false],
  $cinder_eqlx_chap_login       = ['chapadmin'],
  $cinder_eqlx_chap_password    = ['CHANGEME'],
  #  Cinder NetApp
  $cinder_netapp_hostname          = ['netapp1.example.com'],
  $cinder_netapp_login             = ['admin'],
  $cinder_netapp_password          = ['CHANGEME'],
  $cinder_netapp_server_port       = ['80'],
  $cinder_netapp_storage_family    = ['ontap_cluster'],
  $cinder_netapp_transport_type    = ['http'],
  $cinder_netapp_storage_protocol  = ['nfs'],
  $cinder_netapp_nfs_shares        = ['192.168.1.4:/cinder'],
  $cinder_netapp_nfs_shares_config = ['/etc/cinder/shares.conf'],
  $cinder_netapp_volume_list       = ['cindervol1'],
  $cinder_netapp_vfiler            = ['cinder'],
  $cinder_netapp_vserver           = ['cinder'],
  $cinder_netapp_controller_ips    = ['192.168.1.3'],
  $cinder_netapp_sa_password       = ['CHANGEME'],
  $cinder_netapp_storage_pools     = ['pool1'],
  $cinder_backend_netapp_name      = produce_array_with_prefix("netapp", 1, size($cinder_netapp_hostname)),
  #  Cinder RBD
  $cinder_rbd_pool              = 'volumes',
  $cinder_rbd_ceph_conf         = '/etc/ceph/ceph.conf',
  $cinder_rbd_flatten_volume_from_snapshot
                                = false,
  $cinder_rbd_max_clone_depth   = '5',
  $cinder_rbd_user              = 'volumes',
  $cinder_rbd_secret_uuid       = '',

  # Glance
  $glance_db_password           = 'CHANGEME',
  $glance_user_password         = 'CHANGEME',
  $glance_backend               = 'file',

  # Glance RBD
  $glance_rbd_store_user        = 'images',
  $glance_rbd_store_pool        = 'images',

  # Glance_Gluster
  $glance_gluster_volume        = 'glance',
  $glance_gluster_path          = '/srv/gluster/glance',
  $glance_gluster_peers         = [ '192.168.0.4', '192.168.0.5', '192.168.0.6' ],
  $glance_gluster_replica_count = '3',

  # Gluster
  $gluster_open_port_count      = '10',

  # Networking
  $neutron                       = 'false',
  $controller_admin_host         = '172.16.0.1',
  $controller_priv_host          = '172.16.0.1',
  $controller_pub_host           = '172.16.1.1',
  $nova_default_floating_pool    = 'nova',

  # Nova-network specific
  $fixed_network_range           = '10.0.0.0/24',
  $floating_network_range        = '10.0.1.0/24',
  $auto_assign_floating_ip       = 'True',

  # Neutron specific
  $neutron_metadata_proxy_secret = 'CHANGEME',

  $mysql_host                    = '172.16.0.1',
  $amqp_provider                 = 'rabbitmq',
  $amqp_host                     = '172.16.0.1',
  $amqp_username                 = 'openstack',
  $amqp_password                 = 'CHANGEME',
  $enable_ovs_agent              = 'true',
  $tenant_network_type           = 'gre',
  $ovs_vlan_ranges               = undef,
  $ovs_bridge_mappings           = [],
  $ovs_bridge_uplinks            = [],
  $configure_ovswitch            = 'true',
  $enable_tunneling              = 'True',
  $ovs_vxlan_udp_port            = '4789',
  $ovs_tunnel_types              = [],
  $network_device_mtu            = undef,
  $veth_mtu                      = undef,

  # neutron plugin config
  $neutron_core_plugin           = 'neutron.plugins.ml2.plugin.Ml2Plugin',
  # If using the Cisco plugin, use either OVS or n1k for virtualised l2
  $cisco_vswitch_plugin          = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
  # If using the Cisco plugin, Nexus hardware can be used for l2
  $cisco_nexus_plugin            = 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin',
  $agent_type			 = 'ovs',

  # If using the nexus sub plugin, specify the hardware layout by
  # using the following syntax:
  # $nexus_config = { 'SWITCH_IP' => { 'COMPUTE_NODE_NAME' : 'PORT' } },
  $nexus_config                  = undef,

  # Set the nexus login credentials by creating a list
  # of switch_ip/username/password strings as per the example below:
  $nexus_credentials             = undef,

  $n1kv_vsm_ip                   = '0.0.0.0',
  $n1kv_vsm_password             = undef,
  $neutron_conf_additional_params= { 'default_quota' => 'default',
                                     'quota_network' => 'default',
                                     'quota_subnet' => 'default',
                                     'quota_port' => 'default',
                                     'quota_security_group' => 'default',
                                     'quota_security_group_rule' => 'default',
                                     'quota_vip' => 'default',
                                     'quota_pool' => 'default',
                                     'quota_router' => 'default',
                                     'quota_floatingip' => 'default',
                                     'network_auto_schedule' => 'default',
                                   },
  $nova_conf_additional_params   = { 'quota_instances' => 'default',
                                     'quota_cores' => 'default',
                                     'quota_ram' => 'default',
                                     'quota_floating_ips' => 'default',
                                     'quota_fixed_ips' => 'default',
                                     'quota_driver' => 'default',
                                     },
  $n1kv_plugin_additional_params = { 'default_policy_profile' => 'default-pp',
                                     'network_node_policy_profile' => 'default-pp',
                                     'poll_duration' => '10',
                                     'http_pool_size' => '4',
                                     'http_timeout' => '30',
                                     'firewall_driver' => 'neutron.agent.firewall.NoopFirewallDriver',
                                     'enable_sync_on_start' => 'True',
                                     'restrict_policy_profiles' => 'False',
                                     },
  $security_group_api            = 'neutron',
  # Horizon

  $django_debug                  = 'False',
  $help_url                      = 'http://docs.openstack.org',
  $cache_server_ip               = '127.0.0.1',
  $cache_server_port             = '11211',
  $keystone_port                 = '5000',
  $keystone_scheme               = 'http',
  $keystone_default_role         = 'Member',
  $can_set_mount_point           = 'True',
  $api_result_limit              = '1000',
  $log_level                     = 'DEBUG',
  $horizon_app_links             = 'False',
  $support_profile               = 'None',

  # provider network settings
  $provider_vlan_auto_create     = 'false',
  $provider_vlan_auto_trunk      = 'false',
  $mysql_virt_ip_nic             = '172.16.0.1',
  $mysql_virt_ip_cidr_mask       = 'MYSQL_CIDR_MASK',
  $mysql_shared_storage_device   = 'MYSQL_SHARED_STORAGE_DEVICE',
  $mysql_shared_storage_options  = '',
  # e.g. "nfs"
  $mysql_shared_storage_type     = 'MYSQL_SHARED_STORAGE_TYPE',
  $mysql_clu_member_addrs        = 'SPACE_SEPARATED_IP_ADDRS',
  $mysql_resource_group_name     = 'mysqlgroup',

  # SSL
  $ssl                           = 'false',
  $freeipa                       = 'false',
  $mysql_ca                      = '/etc/ipa/ca.crt',
  $mysql_cert                    = undef,
  $mysql_key                     = undef,
  $amqp_ca                       = undef,
  $amqp_cert                     = undef,
  $amqp_key                      = undef,
  $horizon_ca                    = '/etc/ipa/ca.crt',
  $horizon_cert                  = undef,
  $horizon_key                   = undef,
  $amqp_nssdb_password           = 'CHANGEME',

  # Pacemaker
  $pacemaker_cluster_name        = 'openstack',
  $pacemaker_cluster_members     = '',
  $ha_loadbalancer_public_vip    = '172.16.1.10',
  $ha_loadbalancer_private_vip   = '172.16.2.10',
  $ha_loadbalancer_group         = 'load_balancer',
  $fencing_type                  = 'disabled',
  $fence_xvm_clu_iface           = 'eth2',
  $fence_xvm_manage_key_file     = false,
  $fence_xvm_key_file_password   = '12345678isTheSecret',
  $fence_ipmilan_address         = '10.10.10.1',
  $fence_ipmilan_username        = '',
  $fence_ipmilan_password        = '',
  $fence_ipmilan_interval        = '60s',

  # Gluster Servers
  $gluster_device1       = '/dev/vdb',
  $gluster_device2       = '/dev/vdc',
  $gluster_device3       = '/dev/vdd',
  $gluster_fqdn1         = 'gluster-server1.example.com',
  $gluster_fqdn2         = 'gluster-server2.example.com',
  $gluster_fqdn3         = 'gluster-server3.example.com',
  # One port for each brick in a volume
  $gluster_port_count    = '9',
  $gluster_replica_count = '3',
  $gluster_uuid1         = 'e27f2849-6f69-4900-b348-d7b0ae497509',
  $gluster_uuid2         = '746dc27e-b9bd-46d7-a1a6-7b8957528f4c',
  $gluster_uuid3         = '5fe22c7d-dc85-4d81-8c8b-468876852566',
  $gluster_volume1_gid   = '165',
  $gluster_volume1_name  = 'cinder',
  $gluster_volume1_path  = '/cinder',
  $gluster_volume1_uid   = '165',
  $gluster_volume2_gid   = '161',
  $gluster_volume2_name  = 'glance',
  $gluster_volume2_path  = '/glance',
  $gluster_volume2_uid   = '161',
  $gluster_volume3_gid   = '160',
  $gluster_volume3_name  = 'swift',
  $gluster_volume3_path  = '/swift',
  $gluster_volume3_uid   = '160',
) {
}
