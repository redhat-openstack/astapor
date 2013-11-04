
class quickstack::neutron::networker (
  $configure_ovswitch           = $quickstack::params::configure_ovswitch,
  $fixed_network_range          = $quickstack::params::fixed_network_range,
  $floating_network_range       = $quickstack::params::floating_network_range,
  $metadata_proxy_shared_secret = $quickstack::params::metadata_proxy_shared_secret,
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $controller_priv_floating_ip  = $quickstack::params::controller_priv_floating_ip,
  $private_interface            = $quickstack::params::private_interface,
  $public_interface             = $quickstack::params::public_interface,
  $mysql_host                   = $quickstack::params::mysql_host,
  $qpid_host                    = $quickstack::params::qpid_host,
  $verbose                      = $quickstack::params::verbose,
) inherits quickstack::params {

    if str2bool("$configure_ovswitch") {
        vs_bridge { 'br-ex':
            provider => ovs_redhat,
            ensure   => present,
        } ->
        vs_port { 'external':
            bridge    => 'br-ex',
            interface => $public_interface,
            keep_ip   => true,
            sleep     => '30',
            provider  => ovs_redhat,
            ensure    => present,
        }
    }

    class { '::neutron':
        verbose               => true,
        allow_overlapping_ips => true,
        rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
        qpid_hostname         => $qpid_host,
    }
    
    neutron_config {
        'database/connection': value => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron";

        'keystone_authtoken/admin_tenant_name': value => 'admin';
        'keystone_authtoken/admin_user':        value => 'admin';
        'keystone_authtoken/admin_password':    value => $admin_password;
        'keystone_authtoken/auth_host':         value => $controller_priv_floating_ip;
    }

    class { '::neutron::plugins::ovs':
        sql_connection      => "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron",
        tenant_network_type => 'gre',
    }

    class { '::neutron::agents::ovs':
        local_ip         => getvar("ipaddress_${private_interface}"),
        enable_tunneling => true,
    }

    class { '::neutron::agents::dhcp': }

    class { '::neutron::agents::l3': }

    class { 'neutron::agents::metadata':
        auth_password => $admin_password,
        shared_secret => $metadata_proxy_shared_secret,
        auth_url      => "http://${controller_priv_floating_ip}:35357/v2.0",
        metadata_ip   => $controller_priv_floating_ip,
    }

    #class { 'neutron::agents::lbaas': }

    #class { 'neutron::agents::fwaas': }
}
