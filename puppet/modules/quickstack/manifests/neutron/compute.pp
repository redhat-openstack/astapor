# Common quickstack configurations
class quickstack::neutron::compute (
  $admin_password               = $quickstack::params::admin_password,
  $fixed_network_range          = $quickstack::params::fixed_network_range,
  $floating_network_range       = $quickstack::params::floating_network_range,
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $neutron_user_password        = $quickstack::params::neutron_user_password,
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $pacemaker_priv_floating_ip   = $quickstack::params::pacemaker_priv_floating_ip,
  $pacemaker_pub_floating_ip    = $quickstack::params::pacemaker_pub_floating_ip,
  $private_interface            = $quickstack::params::private_interface,
  $public_interface             = $quickstack::params::public_interface,
  $verbose                      = $quickstack::params::verbose,
) inherits quickstack::params {

  # Configure Nova
  nova_config{
      'DEFAULT/libvirt_inject_partition':             value => '-1';

      ### Networking
      #'DEFAULT/service_neutron_metadata_proxy':       value => 'True';
      #'DEFAULT/neutron_metadata_proxy_shared_secret': value => 'secret';

      # To review if obsolete (nova network)
      # 'DEFAULT/auto_assign_floating_ip':              value => 'True';
      # 'DEFAULT/network_host':            value => $pacemaker_priv_floating_ip;
      # 'DEFAULT/metadata_host':           value => $pacemaker_priv_floating_ip;
      # 'DEFAULT/auto_assign_floating_ip': value => 'True';
      # 'DEFAULT/multi_host':              value => 'True';
      # 'DEFAULT/force_dhcp_release':      value => 'False';

      'keystone_authtoken/admin_tenant_name': value => 'admin';
      'keystone_authtoken/admin_user':        value => 'admin';
      'keystone_authtoken/admin_password':    value => $admin_password;
      'keystone_authtoken/auth_host':         value => $pacemaker_priv_floating_ip;
    }

  class { 'nova':
    sql_connection     => "mysql://nova:${nova_db_password}@${pacemaker_priv_floating_ip}/nova",
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "http://${pacemaker_priv_floating_ip}:9292/v1",
    rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
    qpid_hostname      => $pacemaker_priv_floating_ip,
    verbose            => $verbose,
  }

  # uncomment if on a vm
  # GSutclif: Maybe wrap this in a Facter['is-virtual'] test ?
  #file { "/usr/bin/qemu-system-x86_64":
  #    ensure => link,
  #    target => "/usr/libexec/qemu-kvm",
  #    notify => Service["nova-compute"],
  #}
  #nova_config{
  #    "libvirt_cpu_mode": value => "none";
  #}

  class { 'nova::compute::libvirt':
      #libvirt_type                => "qemu",  # uncomment if on a vm
      vncserver_listen            => $::ipaddress,
  }

  class { 'nova::compute':
      enabled => true,
      vncproxy_host => $pacemaker_pub_floating_ip,
      vncserver_proxyclient_address => $::ipaddress,
  }

  class { 'nova::api':
      enabled           => true,
      admin_password    => $nova_user_password,
      auth_host         => $pacemaker_priv_floating_ip,
  }

  #class { 'nova::network':
  #    private_interface => "$private_interface",
  #    public_interface  => "$public_interface",
  #    fixed_range       => "$fixed_network_range",
  #    floating_range    => "$floating_network_range",
  #    network_manager   => "nova.network.manager.FlatDHCPManager",
  #    config_overrides  => {"force_dhcp_release" => false},
  #    create_networks   => true,
  #    enabled           => true,
  #    install_service   => true,
  #}

  ### Neutron
  class { '::neutron':
      allow_overlapping_ips => true,
      rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
      qpid_hostname         => $pacemaker_priv_floating_ip,
  }
  
  # Neutron config
  neutron_config {
      'database/connection': value => "mysql://neutron:${neutron_db_password}@${pacemaker_priv_floating_ip}/neutron";

      'keystone_authtoken/auth_host':         value => $pacemaker_priv_floating_ip;
      'keystone_authtoken/admin_tenant_name': value => 'admin';
      'keystone_authtoken/admin_user':        value => 'admin';
      'keystone_authtoken/admin_password':    value => $admin_password;
  }

  # Plugin
  class { '::neutron::plugins::ovs':
      sql_connection      => "mysql://neutron:${neutron_db_password}@${pacemaker_priv_floating_ip}/neutron",
      tenant_network_type => 'gre',
  }

  # Agent
  class { '::neutron::agents::ovs':
      local_ip         => $::ipaddress,
      enable_tunneling => true,
  } 

  class { '::nova::network::neutron':
      neutron_admin_password    => $neutron_user_password,
      neutron_url               => "http://${pacemaker_priv_floating_ip}:9696",
      neutron_admin_auth_url    => "http://${pacemaker_priv_floating_ip}:35357/v2.0",
  }

  firewall { '001 nova compute incoming':
      proto  => 'tcp',
      dport  => '5900-5999',
      action => 'accept',
  }
}
