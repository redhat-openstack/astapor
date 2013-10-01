Puppet::Parser::Functions::newfunction(
  :port_range,
  :first_port  => :rvalue,
  :interval    => :rvalue,
  :doc => "Return an array of ports of interval size") do |args|
  	counter= 0
    list = []
	for i in 1..interval.size
		list << first_port + counter
		counter+=1
	end
    return list
end

