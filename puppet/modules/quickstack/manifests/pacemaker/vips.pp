define quickstack::pacemaker::vips(
  $public_vip,
  $private_vip,
  $admin_vip,
  $pcmk_group         = $title,
  $haproxy_constraint = true,
  ) {

  Exec['stonith-setup-complete'] ->
  quickstack::pacemaker::resource::ip { "ip-${pcmk_group}-pub":
    ip_address => "$public_vip",
  }
  if $haproxy_constraint {
    Quickstack::Pacemaker::Resource::Service['haproxy'] ->
    quickstack::pacemaker::constraint::typical{ "haproxy-${pcmk_group}-pub-const" :
      first_resource  => "haproxy-clone",
      second_resource => "ip-${pcmk_group}-pub-${public_vip}",
    }
    Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-pub"] ->
    Quickstack::Pacemaker::Constraint::Typical["haproxy-${pcmk_group}-pub-const"]
  }

  if ( $public_vip != $private_vip ) {
    Exec['stonith-setup-complete'] ->
    quickstack::pacemaker::resource::ip { "ip-${pcmk_group}-prv":
      ip_address => "$private_vip",
    } ->
    quickstack::pacemaker::constraint::colocation { "ip-${pcmk_group}-pub-prv-colo" :
      source => "ip-${pcmk_group}-prv-${private_vip}",
      target => "ip-${pcmk_group}-pub-${public_vip}",
    }
    if $haproxy_constraint {
      Quickstack::Pacemaker::Resource::Service['haproxy'] ->
      quickstack::pacemaker::constraint::typical{ "haproxy-${pcmk_group}-prv-const" :
        first_resource  => "haproxy-clone",
        second_resource => "ip-${pcmk_group}-prv-${private_vip}",
      }
      Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-pub"] ->
      Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-prv"] ->
      Quickstack::Pacemaker::Constraint::Typical["haproxy-${pcmk_group}-prv-const"] ->
      Quickstack::Pacemaker::Constraint::Colocation["ip-${pcmk_group}-pub-prv-colo"]
    }
  }

  if ( ($admin_vip != $private_vip) and ($admin_vip != $public_vip) ) {
    Exec['stonith-setup-complete'] ->
    quickstack::pacemaker::resource::ip { "ip-${pcmk_group}-adm":
      ip_address => "$admin_vip",
    } ->
    quickstack::pacemaker::constraint::colocation { "ip-${pcmk_group}-pub-adm-colo" :
      source => "ip-${pcmk_group}-adm-${admin_vip}",
      target => "ip-${pcmk_group}-pub-${public_vip}",
    }
    if $haproxy_constraint {
      Quickstack::Pacemaker::Resource::Service['haproxy'] ->
      quickstack::pacemaker::constraint::typical{ "haproxy-${pcmk_group}-adm-const" :
        first_resource  => "haproxy-clone",
        second_resource => "ip-${pcmk_group}-adm-${admin_vip}",
      }
      Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-pub"] ->
      Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-adm"] ->
      Quickstack::Pacemaker::Constraint::Typical["haproxy-${pcmk_group}-adm-const"] ->
      Quickstack::Pacemaker::Constraint::Colocation["ip-${pcmk_group}-pub-adm-colo"]
    }
  }
}
