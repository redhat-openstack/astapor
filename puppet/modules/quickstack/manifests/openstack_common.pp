# Class for nodes running any OpenStack services
class quickstack::openstack_common {

  include quickstack::firewall::common
  if (str2bool($::selinux) and $::operatingsystem != "Fedora") {
      package{ 'openstack-selinux':
          ensure => present, }
  }

  # Stop firewalld since everything uses iptables. Firewalld provider will
  # have to be implemented in puppetlabs-firewall in future.
  service { "firewalld":
    ensure => "stopped",
    enable => false,
    before => Service['iptables'],
  }

  service { "auditd":
    ensure => "running",
    enable => true,
  }
}
