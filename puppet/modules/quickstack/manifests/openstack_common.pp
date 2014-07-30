# Class for nodes running any OpenStack services
class quickstack::openstack_common {

  include quickstack::firewall::common
  if (str2bool($::selinux) and $::operatingsystem != "Fedora") {
      package{ 'openstack-selinux':
          ensure => present, }
  }

  # Stop firewalld since everything uses iptables for now (same as
  # packstack did), but save and restore the initial firewall rules
  # (allow loopback, reject at the end of the chain etc.)
  exec { "iptables-save-before-disabling-firewalld":
    command => "/usr/sbin/iptables-save > /etc/sysconfig/iptables"
  } ->
  service { "firewalld":
    ensure => "stopped",
    enable => false,
  }

  service { "auditd":
    ensure => "running",
    enable => true,
  }
}
