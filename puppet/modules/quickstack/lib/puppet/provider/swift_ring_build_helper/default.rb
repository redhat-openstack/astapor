Puppet::Type.type(:swift_ring_build_helper).provide(:default) do
  desc 'A base resource definition for a pacemaker resource'

  ### overloaded methods
  def create
    @resource[:swift_storage_ips].each_with_index do |ipaddr, index|
      zone = index+1
      if ! srb_cmd_add_all_three(zone,ipaddr,
                                 @resource[:swift_storage_device]) then
        return false
      end
    end
    srb_cmd_rebalance_all_three
  end

  # kind of silly, but can run into an error if next 2 methods do not
  # exist in the case where exists? returns true.
  def swift_storage_ips
    @resource[:swift_storage_ips]
  end
  def swift_storage_device
    @resource[:swift_storage_device]
  end

  def destroy
    cmd = 'resource delete ' + @resource[:name]
    #pcs('delete', cmd)
  end

  def exists?
    cmd = "cd /etc/swift && swift-ring-builder account.builder search z1 2>&1"
    cmd_out = `#{cmd}`
    if $?.exitstatus == 2 then
      # No zone 1 exists.  All is good (false is good here)
      return false
    elsif $?.exitstatus == 0 then
      Puppet.debug('swift_ring_build_helper: Not creating ring files because '+
                 'devices have already been added to account.builder.')
    else
      Puppet.debug("swift_ring_build_helper: unexpected return value "+
                   $?.exitstatus.to_s + " for #{cmd}\n #{cmd_out}")
    end
    return true
  end

  def srb_cmd_add_all_three(zone,ipaddr,device)
    srb_cmd_add('account',zone,ipaddr,device,'6002') and
    srb_cmd_add('container',zone,ipaddr,device,'6001') and
    srb_cmd_add('object',zone,ipaddr,device,'6000')
  end
  def srb_cmd_add(ringtype,zone,ipaddr,device,port)
    # ringtype is "account", "object" or "container"
    cmd = "cd /etc/swift && /usr/bin/swift-ring-builder #{ringtype}.builder add "+
      "r0z#{zone}-#{ipaddr}:#{port}/#{device} 100 2>&1"
    Puppet.debug(cmd)
    cmd_out = `#{cmd}`
    if $?.exitstatus != 0 then
      raise Puppet::Error, "swift_ring_build_helper: Command Failed: "+
                   "#{cmd}\n#{cmd_out}"
      return false
    end
    `sleep 1`
    return true
  end
  def srb_cmd_rebalance_all_three()
    srb_cmd_rebalance('account') and
    srb_cmd_rebalance('container') and
    srb_cmd_rebalance('object')
  end
  def srb_cmd_rebalance(ringtype)
    # ringtype is "account", "object" or "container"
    cmd = "cd /etc/swift && /usr/bin/swift-ring-builder #{ringtype}.builder rebalance 2>&1"
    Puppet.debug(cmd)
    cmd_out = `#{cmd}`
    if $?.exitstatus != 0 then
      raise Puppet::Error, "swift_ring_build_helper: Command Failed: "+
                   "#{cmd}\n#{cmd_out}"
      return false
    end
    return true
  end

end
