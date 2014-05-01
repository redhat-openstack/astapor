module Puppet::Parser::Functions
  newfunction(:amqp_backend, :type => :rvalue, :doc => <<-EOS
This returns the AMQP backend string for the given component and backend type
EOS
  ) do |arguments|

    raise(Puppet::ParseError, "amqp_backend(): Wrong number of arguments " +
      "given (#{arguments.size} for 2)") if arguments.size != 2

    component = arguments[0]
    backend = arguments[1] == 'qpid' ? 'qpid' : 'kombu'
    "#{component}.openstack.common.rpc.impl_#{backend}"
  end
end
