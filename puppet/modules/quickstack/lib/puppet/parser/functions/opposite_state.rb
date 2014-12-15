module Puppet::Parser::Functions
    newfunction(:opposite_state, :type => :rvalue, :doc => <<-EOS
Returns opposite state of first argument
EOS
) do |arguments|

    raise(Puppet::ParseError, "neutron_enabled(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    if arguments[0] =~ /true/i or arguments[0] == true
      false
    else
      true
    end
  end
end
