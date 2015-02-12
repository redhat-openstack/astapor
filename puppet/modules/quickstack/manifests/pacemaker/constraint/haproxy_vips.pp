# A generic wrapper to start haproxy before a set of vips
# Important for reboots

define quickstack::pacemaker::constraint::haproxy_vips(
  $public_vip,
  $private_vip,
  $admin_vip,
  $pcmk_group = $title,
  ) {

  Quickstack::Pacemaker::Resource::Generic['haproxy'] ->
  quickstack::pacemaker::constraint::atypical{ "haproxy-${pcmk_group}-pub-const" :
    first_resource  => "ip-${pcmk_group}-pub-${public_vip}",
    second_resource => "haproxy-clone",
  }
  Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-pub"] ->
  Quickstack::Pacemaker::Constraint::Atypical["haproxy-${pcmk_group}-pub-const"]

  if ( $public_vip != $private_vip ) {
    Quickstack::Pacemaker::Resource::Generic['haproxy'] ->
    quickstack::pacemaker::constraint::atypical{ "haproxy-${pcmk_group}-prv-const" :
      first_resource  => "ip-${pcmk_group}-prv-${private_vip}",
      second_resource => "haproxy-clone",
    }
    Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-prv"] ->
    Quickstack::Pacemaker::Constraint::Atypical["haproxy-${pcmk_group}-prv-const"]
  }

  if ( ($admin_vip != $private_vip) and ($admin_vip != $public_vip) ) {
    Quickstack::Pacemaker::Resource::Generic['haproxy'] ->
    quickstack::pacemaker::constraint::atypical{ "haproxy-${pcmk_group}-adm-const" :
      first_resource  => "ip-${pcmk_group}-adm-${admin_vip}",
      second_resource => "haproxy-clone",
    }
    Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-adm"] ->
    Quickstack::Pacemaker::Constraint::Atypical["haproxy-${pcmk_group}-adm-const"]
  }
}
