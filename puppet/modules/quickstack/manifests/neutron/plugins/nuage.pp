class quickstack::neutron::plugins::nuage (
$neutron_db_password  = undef,
$mysql_host           = '127.0.0.1',
$controller_priv_host = '127.0.0.1',
$keystone_admin_token = undef,
$net_partition        = 'Openstack_Default',
$vsdhostname          = '127.0.0.1',
$vsdport              = '8443',
$vsdusername          = 'csproot',
$vsdpassword          = 'csproot'
) {
  package { 'nuagenetlib' : ensure => present }
  ->
  file {
  '/etc/neutron/plugins/nuage':
	ensure  => directory;
  '/etc/neutron/plugins/nuage/nuage_plugin.ini':
	ensure  => present,
  	content => template("quickstack/nuage_plugin.ini.erb");
  '/etc/neutron/plugin.ini':
	ensure  => link,
	target  => '/etc/neutron/plugins/nuage/nuage_plugin.ini',
        require => File['/etc/neutron/plugins/nuage','/etc/neutron/plugins/nuage/nuage_plugin.ini'];
 }
}
