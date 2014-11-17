class quickstack::neutron::agent::nuage (
$defaultbridge     = 'alubr0',
$connectiontype    = 'tcp',
$activecontroller  = undef,
$standbycontroller = undef,
$agentport	   = 9697, 
$novaip            = undef,
$metadataport      = 8775,
$metadatasecret    = undef,
$novausername      = 'admin',
$novapassword      = undef,
$keystoneip        = undef 
) {
package { ['openstack-neutron-openvswitch','openvswitch'] : ensure => absent }
->
package { ['python-twisted','perl-JSON','qemu-kvm','vconfig','nuage-openvswitch','nuage-metadata-agent'] : ensure => present }
->
file {
 '/etc/default/openvswitch':
 ensure  => present,
 content => template('quickstack/openvswitch.erb'); 
 '/etc/default/nuage-metadata-agent':
 ensure  => present,
 content => template('quickstack/nuage-metadata-agent.erb'); 
     }
->
service {'openvswitch':
 ensure     => running,
 enable     => true,
 hasrestart => true,
 subscribe  => File['/etc/default/openvswitch','/etc/default/nuage-metadata-agent'];
       }
->
exec {"nuage_fix":
 command => "service openvswitch restart",
 path    => "$::path",
 unless  => "ovs-vsctl show | grep -q $activecontroller";
     }
}
