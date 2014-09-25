module Puppet::Parser::Functions
    newfunction(:amqp_port, :type => :rvalue, :doc => <<-EOS
This returns the amqp port for standard or ssl services
EOS
) do |arguments|
    Puppet::Parser::Functions.autoloader.loadall
    raise(Puppet::ParseError, "amqp_port(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    ssl = arguments[0] ||= false
    if ssl
      '5671'
    else
      '5672'
    end
  end
end
