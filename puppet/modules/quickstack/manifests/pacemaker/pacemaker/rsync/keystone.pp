class quickstack::pacemaker::rsync::keystone (
  $keystone_private_vip,
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

  quickstack::pacemaker::rsync::get { '/etc/keystone/ssl':
    source           => "rsync://$keystone_private_vip/keystone/",
    override_options => "aIX",
    purge            => true,
    unless           => "/tmp/ha-all-in-one-util.bash i_am_vip $keystone_private_vip",
  }
  ->

  quickstack::rsync::simple { "keystone":
    path            => '/etc/keystone/ssl',
    bind_addr       => "$keystone_private_vip",
    max_connections => 10,
  }

  # NOTE: we may also want to add a module setting up known hosts, and then we
  # can have client using an ssh key in addition to having to be in the
  # hosts_allow list

}
