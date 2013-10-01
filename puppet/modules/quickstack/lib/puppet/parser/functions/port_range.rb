Puppet::Parser::Functions::newfunction(
  :port_range,
  :first_port => :rvalue,
  :range_size => :rvalue,
  :doc => "Return an array of ports starting at first port of range_size") do |args|
    list = []
	for counter in 0..range_size-1
		list << (first_port.to_i + counter).to_s
	end
    return list
end

