# Common quickstack configurations
class quickstack::nova_network::compute (
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $fixed_network_range         = $quickstack::params::fixed_network_range,
  $floating_network_range      = $quickstack::params::floating_network_range,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $controller_priv_fqdn        = $quickstack::params::controller_priv_fqdn,
  $private_interface           = $quickstack::params::private_interface,
  $public_interface            = $quickstack::params::public_interface,
  $mysql_host                  = $quickstack::params::mysql_host,
  $qpid_host                   = $quickstack::params::qpid_host,
  $verbose                     = $quickstack::params::verbose,
) inherits quickstack::params {

    # Configure Nova
    nova_config{
        'DEFAULT/auto_assign_fqdn':  value => 'True';
        #"DEFAULT/network_host":            value => ${controller_priv_fqdn;
        "DEFAULT/network_host":             value => "$::ipaddress";
        "DEFAULT/libvirt_inject_partition": value => "-1";
        #"DEFAULT/metadata_host":           value => "$controller_priv_fqdn";
        "DEFAULT/metadata_host":            value => "$::ipaddress";
        "DEFAULT/multi_host":               value => "True";
    }

    class { 'nova':
        sql_connection     => "mysql://nova:${nova_db_password}@${mysql_host}/nova",
        image_service      => 'nova.image.glance.GlanceImageService',
        glance_api_servers => "http://$controller_priv_fqdn:9292/v1",
        rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
        qpid_hostname      => $qpid_host,
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
        vncserver_listen            => "$::ipaddress",
    }

    class {"nova::compute":
        enabled => true,
        vncproxy_host => "$controller_priv_fqdn",
        vncserver_proxyclient_address => "$ipaddress",
    }

    class { 'nova::api':
        enabled           => true,
        admin_password    => "$nova_user_password",
        auth_host         => "$controller_priv_fqdn",
    }

    class { 'nova::network':
        private_interface => "$private_interface",
        public_interface  => "$public_interface",
        fixed_range       => "$fixed_network_range",
        floating_range    => "$floating_network_range",
        network_manager   => "nova.network.manager.FlatDHCPManager",
        config_overrides  => {"force_dhcp_release" => false},
        create_networks   => true,
        enabled           => true,
        install_service   => true,
    }

    firewall { '001 nova compute incoming':
        proto    => 'tcp',
        dport    => '5900-5999',
        action   => 'accept',
    }

    class { 'ceilometer':
        metering_secret => $ceilometer_metering_secret,
        qpid_hostname   => $qpid_host,
        rpc_backend     => 'ceilometer.openstack.common.rpc.impl_qpid',
        verbose         => $verbose,
        debug           => true,
    }

    class { 'ceilometer::agent::compute':
        auth_url      => "http://${controller_priv_fqdn}:35357/v2.0",
        auth_password => $ceilometer_user_password,
    }
}
