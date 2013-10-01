module Puppet::Parser::Functions
	newfunction(:port_range, :type => :rvalue,
	:doc => "Return an array of ports from first port to interval size") do |args|
	list = []
	p args[1].class
	for counter in 0..(args[1].to_i - 1)
		list << (args[0].to_i + counter).to_s
	end
  	return list
  end
end
