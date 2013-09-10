  
class quickstack::neutron::networker (
  $fixed_network_range        = $quickstack::params::fixed_network_range,
  $floating_network_range     = $quickstack::params::floating_network_range,
  $neutron_db_password        = $quickstack::params::neutron_db_password,
  $nova_db_password           = $quickstack::params::nova_db_password,
  $nova_user_password         = $quickstack::params::nova_user_password,
  $pacemaker_priv_floating_ip = $quickstack::params::pacemaker_priv_floating_ip,
  $private_interface          = $quickstack::params::private_interface,
  $public_interface           = $quickstack::params::public_interface,
  $verbose                    = $quickstack::params::verbose,
) inherits quickstack::params {

    ### Neutron stuf
    # Configures everything in neutron.conf
    class { '::neutron':
        verbose               => true,
        allow_overlapping_ips => true,
        rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
        qpid_hostname         => $pacemaker_priv_floating_ip,
    }
    
    # To be done by neutron module or something missing?
    neutron_config {
        'database/connection': value => "mysql://neutron:${neutron_db_password}@${pacemaker_priv_floating_ip}/neutron";

        'keystone_authtoken/admin_tenant_name': value => 'admin';
        'keystone_authtoken/admin_user':        value => 'admin';
        'keystone_authtoken/admin_password':    value => $admin_password;
        'keystone_authtoken/auth_host':         value => $pacemaker_priv_floating_ip;
    }
  
    # OVS Plugin
    class { '::neutron::plugins::ovs':
        sql_connection      => "mysql://neutron:${neutron_db_password}@${pacemaker_priv_floating_ip}/neutron",
        tenant_network_type => 'gre',
    }

    # Agents
    class { '::neutron::agents::ovs':
        local_ip         => $::ipaddress,
        enable_tunneling => true,
    }

    class { '::neutron::agents::dhcp': }

    class { '::neutron::agents::l3': }

    class { 'neutron::agents::metadata': 
        auth_password => $admin_password,
        shared_secret => 'shared_secret',
        auth_url      => "http://${pacemaker_priv_floating_ip}:35357/v2.0",
        metadata_ip   => $pacemaker_priv_floating_ip,
    }

    #class { 'neutron::agents::lbaas': }
    
    #class { 'neutron::agents::fwaas': }

    # Neutron external network for br-ex
    #keystone_tenant { 'admin':
    #    ensure => present,
    #}

    #neutron_network { 'public':
    #    ensure          => present,
    #    router_external => 'True',
    #    tenant_name     => 'admin',

    #neutron_subnet { 'public_subnet':
    #    ensure           => 'present',
    #    cidr             => '10.16.16.0/22',
    #    gateway_ip       => '10.16.19.254',
    #    allocation_pools => 'start=10.16.18.1,end=10.16.18.254',
    #    network_name     => 'public',
    #    tenant_name      => 'admin',
    #}
}
