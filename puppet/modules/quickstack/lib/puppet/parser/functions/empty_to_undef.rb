module Puppet::Parser::Functions
  newfunction(:empty_to_undef, :type => :rvalue, :doc => <<-EOS
Given a value, this will in most cases just return the given value.
If the given value is an empty string, this will return a value
corresponding to the puppet value "undef".
EOS
  ) do |arguments|

    raise(Puppet::ParseError, "empty_to_undef(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    string = arguments[0]
    if string.is_a?(String) and string == ''
      return nil
    end

    return string
  end
end
