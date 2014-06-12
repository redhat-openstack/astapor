class quickstack::pacemaker::rsync::galera (
  $cluster_control_ip,
) {

  Exec {
    path => '/usr/bin:/usr/sbin:/bin',
  }

  if (($::selinux != "false") and (! defined(Selboolean['rsync_client']))) {
    selboolean { 'rsync_client':
      value      => on,
      persistent => true,
    }
  }

  if (has_interface_with("ipaddress", $cluster_control_ip)) {    
    quickstack::rsync::simple { "galera":
      path            => '/etc/pki/galera',
      bind_addr       => "$cluster_control_ip",
      max_connections => 10,
    }
  } else {
    quickstack::pacemaker::rsync::get { '/etc/pki/galera':
      source           => "rsync://$cluster_control_ip/galera/",
      override_options => "aIX",
      purge            => true,
    }
  }

  # NOTE: we may also want to add a module setting up known hosts, and then we
  # can have client using an ssh key in addition to having to be in the
  # hosts_allow list

}
