Puppet::Type.newtype(:swift_ring_build_helper) do
  @doc = "Base resource definition for building swift rings"

  ensurable

  newparam(:name) do
    desc "A unique name for the resource"
  end

  newproperty(:swift_storage_ips, :array_matching => :all) do
    desc "an array of the ip addresses of the swift storage nodes"    
  end

  newproperty(:swift_storage_device) do
    desc "the name of the storage device on each swift node"    
  end

end
