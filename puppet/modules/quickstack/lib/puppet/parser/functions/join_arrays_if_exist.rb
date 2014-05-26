module Puppet::Parser::Functions
  newfunction(:join_arrays_if_exist, :type => :rvalue, :doc => <<-EOS
Takes names of local variables which might or might not exist. Looks
for arrays in the local variables specified, and joins them
together. If no array is found among the variables, returns [].
EOS
  ) do |arguments|

    retval = []

    arguments.each do |array_name|
      array = lookupvar(array_name)
      if array.is_a?(Array)
        retval += array
      end
    end

    return retval
  end
end
