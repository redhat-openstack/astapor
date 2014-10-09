class quickstack::pacemaker::stonith (
  $fence_ipmilan                    = false,
  $fence_ipmilan_address            = "",
  $fence_ipmilan_username           = "",
  $fence_ipmilan_password           = "",
  $fence_ipmilan_interval           = "60s",
  $fence_ipmilan_hostlist           = "",
  $fence_ipmilan_host_to_address    = [],
  $fence_ipmilan_expose_lanplus     = "true",
  $fence_ipmilan_lanplus_options    = "",
  $fence_xvm                        = false,
  $fence_xvm_manage_key_file        = "false",
  $fence_xvm_key_file_password      = "",
  $fence_xvm_port                   = "",
  # COMING SOON
  # $fence_vmware_soap                = false,
  # ... possibly plus a bunch of fence_vmware_soap params
  # $fence_rhevm                      = false,
  # ... possibly plus a bunch of fence_rhevm params
) {
  include quickstack::pacemaker::common

  if ( ! str2bool_i(map_params('stonith_enabled'))) {
    class {'pacemaker::stonith':
      disable => true,
    }
    Class['pacemaker::corosync'] -> Class['pacemaker::stonith']
  } else {
    class {'pacemaker::stonith':
      disable => false,
    }
    $fencing_agent_specified = str2bool_i($fence_ipmilan) or str2bool_i($fence_xvm)
    if ( ! $fencing_agent_specified ) {
      notify{"fence agent is specified but stonith_enabled is false"}
        loglevel => alert,
    }

    if str2bool_i("$fence_ipmilan") {
      # we still need to use the quickstack version if ref arch still
      # needs a way to specify "blank" lanplus=
      class {'quickstack::pacemaker::stonith::ipmilan':
        address         => $fence_ipmilan_address,
        username        => $fence_ipmilan_username,
        password        => $fence_ipmilan_password,
        interval        => $fence_ipmilan_interval,
        pcmk_host_list  => $fence_ipmilan_hostlist,
        host_to_address => $fence_ipmilan_host_to_address,
        lanplus         => str2bool_i("$fence_ipmilan_expose_lanplus"),
        lanplus_options => $fence_ipmilan_lanplus_options,
      }
      Class['pacemaker::stonith'] -> Class['quickstack::pacemaker::stonith::ipmilan'] -> Exec['stonith-setup-complete']
    }

    if str2bool_i("$fence_xvm") {
      class {'pacemaker::stonith::fence_xvm':
        name              => "$::hostname",
        manage_key_file   => str2bool_i("$fence_xvm_manage_key_file"),
        key_file_password => $fence_xvm_key_file_password,
        port              => $fence_xvm_port,  # the domname or uuid of the vm
      }
      Class['pacemaker::stonith'] -> Class['pacemaker::stonith::fence_xvm'] -> Exec['stonith-setup-complete']
    }
    ##############################
    # A couple of options, using fence_vmware_soap as an example

    ##############################
    # OPTION 1
    # getting closer to "dynamic" -- staypuft would be responsible for adding
    # https://github.com/radez/puppet-pacemaker/blob/master/manifests/stonith/fence_vmware_soap.pp
    # to the HA controller host group dynamically
    #
    # if str2bool_i("$fence_vmware_soap") {    
    #   include ::pacemaker::stonith::fence_vmware_soap
    #   Class['pacemaker::stonith'] -> Class['pacemaker::stonith::fence_vmware_soap'] -> Exec['stonith-setup-complete']
    # }
    #
    # footnote: it may be possible to move the above ordering
    # upstream.  then, this manifest wouldn't need any
    # fence_vmware_soap (or any other fence type) references!

    ##############################
    # OPTION 2
    # wrap it.  would need to add all the $fence_vmware_soap_ params to this manifest.
    #
    # if str2bool_i("$fence_vmware_soap") {    
    #   class {'pacemaker::stonith::fence_vwmare_soap':
    # 	ipaddr        = $fence_vmware_soap_ipaddr,
    # 	login         = $fence_vmware_soap_login,
    # 	passwd        = $fence_vmware_soap_passwd,
    # 	ssl           = $fence_vmware_soap_ssl,
    # 	notls         = $fence_vmware_soap_notls,
    # 	port          = $fence_vmware_soap_port,
    # 	ipport        = $fence_vmware_soap_ipport,
    # 	inet4_only    = $fence_vmware_soap_inet4_only,
    # 	inet6_only    = $fence_vmware_soap_inet6_only,
    # 	passwd_script = $fence_vmware_soap_passwd_script,
    # 	ssl_secure    = $fence_vmware_soap_ssl_secure,
    # 	ssl_insecure  = $fence_vmware_soap_ssl_insecure,
    # 	verbose       = $fence_vmware_soap_verbose,
    # 	debug         = $fence_vmware_soap_debug,
    # 	separator     = $fence_vmware_soap_separator,
    # 	power_timeout = $fence_vmware_soap_power_timeout,
    # 	shell_timeout = $fence_vmware_soap_shell_timeout,
    # 	login_timeout = $fence_vmware_soap_login_timeout,
    # 	power_wait    = $fence_vmware_soap_power_wait,
    # 	delay         = $fence_vmware_soap_delay,
    # 	retry_on      = $fence_vmware_soap_retry_on,
    #   # can keep default for params: interval, ensure, pcmk_host_value
    #   }
    #   Class['pacemaker::stonith'] -> Class['pacemaker::stonith::fence_vmware_soap'] -> Exec['stonith-setup-complete']
    # }

    exec { "all-nodes-joined-cluster":
      # wait for all nodes to join the cluster, rather just the number
      # required for quorum.  e.g., in a three node cluster, wait for
      # all three nodes to join rather than proceeding after quorum is
      # acheived after only two nodes joining.  this is so that
      # fencing doesn't prematurely fence a node that hasn't joined
      # cluster yet.
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      path => '/usr/bin:/usr/sbin:/bin',
      command => 'crm_mon --as-xml 2>&1 | grep -e "<node .*online=\"false\"" -e "<node .*pending=\"true\"" -e "<node .*unclean=\"true\"" -e "[C|c]onnection refused" >/dev/null 2>&1; test "$?" == "1"',
    }

    Class['pacemaker::corosync'] -> Exec['all-nodes-joined-cluster'] ->
    Class['pacemaker::stonith']
  }

}