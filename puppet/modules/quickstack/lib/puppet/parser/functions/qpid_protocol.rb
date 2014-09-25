module Puppet::Parser::Functions
    newfunction(:qpid_protocol, :type => :rvalue, :doc => <<-EOS
This returns the qpid protocol depending on ssl
EOS
) do |arguments|
    Puppet::Parser::Functions.autoloader.loadall
    raise(Puppet::ParseError, "qpid_protocol(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    ssl = arguments[0] ||= false
    if ssl
      'ssl'
    else
      'tcp'
    end
  end
end
