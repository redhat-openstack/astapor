Puppet::Parser::Functions::newfunction(
  :port_range,
  :peers => :rvalue,
  :port  => :rvalue,
  :doc => "Return an array of ports interval for the peers list") do |args|
  	counter= 0
    list = []
	for i in 1..peers.size
		list << port + counter
		counter+=1
	end
    return list
end

