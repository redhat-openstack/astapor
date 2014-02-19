class quickstack::pacemaker::qpid (
    $qpid_ip = '192.168.200.22',
) {
    include 'quickstack::pacemaker::common'
    class {"qpid::server":
        auth => "no",
	service_ensure => 'stopped',
	# maybe use this when packstack-modules-puppet includes a newer
        # qpid mdoule
        #manage_service => false,
    } ->

    Class["quickstack::pacemaker::common"] ->
    exec { 'sleep 240 let pcs settle':
         command => "/bin/sleep 240" } ->

    pacemaker::resource::ip { "ip-$qpid_ip":
        ip_address => "$qpid_ip",
        group => 'openstack_qpid',
    }
    ->
    pacemaker::resource::lsb { 'qpidd':
        group => 'openstack_qpid',
        require => [ Pacemaker::Resource::Ip["ip-$qpid_ip"] ],
        clone => true,
    }

    firewall { '001 qpid incoming':
        proto    => 'tcp',
        dport    => ['5672'],
        action   => 'accept',
    }

}
