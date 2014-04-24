# Class for nodes running any OpenStack services
class quickstack::openstack_common(
  $ntp_servers = [ '0.pool.ntp.org',
                   '1.pool.ntp.org',
                   '2.pool.ntp.org' ],
) {

  if str2bool($::selinux) and $::operatingsystem != "Fedora" {
    package{ 'openstack-selinux':
        ensure => present,
    }
  }

  class { '::ntp':
    servers => $ntp_servers,
  }
}
