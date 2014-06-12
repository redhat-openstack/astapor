define quickstack::pacemaker::vips(
  $public_vip,
  $private_vip,
  $admin_vip,
  $pcmk_group = $title,
  ) {

  Exec['stonith-setup-complete'] ->
  quickstack::pacemaker::resource::ip { "ip-${pcmk_group}_${public_vip}":
    ip_address => "$public_vip",
  }

  if ( $public_vip != $private_vip ) {
    Exec['stonith-setup-complete'] ->
    quickstack::pacemaker::resource::ip { "ip-${pcmk_group}_${private_vip}":
      ip_address => "$private_vip",
    }
  }

  if ( ($admin_vip != $private_vip) and ($admin_vip != $public_vip) ) {
    Exec['stonith-setup-complete'] ->
    quickstack::pacemaker::resource::ip { "ip-${pcmk_group}_${admin_vip}":
      ip_address => "$admin_vip",
    }
  }
}
