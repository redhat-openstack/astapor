class quickstack::pacemaker::qpid {
  pacemaker::resource::lsb { 'qpidd':
    group   => 'openstack_qpid',
    clone   => true,
  }

  class {'::quickstack::firewall::qpid':}

  Class['::qpid::server'] ->
  Class['::quickstack::pacemaker::common'] ->
  Class['::quickstack::pacemaker::qpid']
}
