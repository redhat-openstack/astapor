module Puppet::Parser::Functions
	newfunction(:port_range, :type => :rvalue,
	:doc => "Return an array of ports from first port to interval size") do |args|
	list = []
	last -= args[1].to_i
	for counter in 0..last
		list << (args[0].to_i + counter).to_s
	end
  	return list
  end
end
