class quickstack::pacemaker::stonith::ipmilan (
  $address         = "10.10.10.1",
  $username        = "",
  $password        = "",
  $interval        = "60s",
  $ensure          = "present",
  $lanplus         = false,
  $lanplus_options = "",
  $pcmk_host_list  = "",
  $resource_params = "",
  $host_to_address = [],
  ) {

  # a string that looks like
  # "cluster_node_name1,ipmilan_address1,cluster_node_name2,ipmilan_address2,..."
  # with any errant single quotes, double quotes, or white space removed
  # and ":" replaced with ","
  $host_to_address_string = inline_template('<%= @host_to_address.map {
    |x| x.gsub(/\s+/, "").gsub("\'", "").gsub("\"", "").gsub(":",",")}.join(",") +"," %>')

  # at runtime, determine what the relevant ipmilan address is based
  # on the current node's cluster node name.  the pattern here is that every
  # node is adding its own stonith device.
  $real_address = $address ? {
      ''      => "$(/bin/echo $host_to_address_string | /usr/bin/perl -p -e \"s/.*$(/usr/sbin/crm_node -n),(.*?),.*/\\\$1/\")",
      default => "${address}",
  }

  if($ensure == absent) {
    exec { "Removing stonith::ipmilan":
      command => "/usr/sbin/pcs stonith delete stonith-ipmilan-${real_address}",
      onlyif  => "/usr/sbin/pcs stonith show stonith-ipmilan-${real_address} > /dev/null 2>&1",
      require => Class['pacemaker::corosync'],
    }
  } else {
    $username_chunk = $username ? {
      ''      => '',
      default => "login=${username}",
    }
    $password_chunk = $password ? {
      ''      => '',
      default => "passwd=${password}",
    }
    $pcmk_host_list_val = $pcmk_host_list ? {
      ''      => '$(/usr/sbin/crm_node -n)',
      default => "${pcmk_host_list}",
    }
    $pcmk_host_list_chunk = $pcmk_host_list ? {
      ''      => 'pcmk_host_list="$(/usr/sbin/crm_node -n)"',
      default => "pcmk_host_list=\"${pcmk_host_list}\"",
    }
    $lanplus_chunk = $lanplus ? {
      false   => '',
      ''      => '',
      default => "lanplus=\"${lanplus_options}\"",
    }
    $_resource_params = $resource_params ? {
      ''      => '',
      default => "${resource_params}",
    }

    package { "ipmitool":
      ensure => installed,
    } ->
    exec { "Creating stonith::ipmilan":
      command => "/usr/sbin/pcs stonith create stonith-ipmilan-${real_address} fence_ipmilan ${pcmk_host_list_chunk} ipaddr=${real_address} ${username_chunk} ${password_chunk} ${lanplus_chunk} ${_resource_params} op monitor interval=${interval}",
      unless  => "/usr/sbin/pcs stonith show stonith-ipmilan-${real_address} > /dev/null 2>&1",
      require => Class['pacemaker::corosync'],
    } ->
    exec { "adding non-local constraint stonith::ipmilan ${address}":
      command => "/usr/sbin/pcs constraint location stonith-ipmilan-${real_address} avoids ${pcmk_host_list_val}",
    }
  }
}
