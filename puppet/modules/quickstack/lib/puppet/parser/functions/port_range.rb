Puppet::Parser::Functions::newfunction(
  :first_port,
  :interval,
  :type => :rvalue,
  :doc  => "Return an array of ports from first port to interval size") do |args|
    list = []
	for counter in 0..args[1]-1
		list << (args[0].to_i + counter).to_s
	end
    return list
end

