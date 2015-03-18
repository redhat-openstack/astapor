module Puppet::Parser::Functions
    newfunction(:produce_array_with_prefix, :type => :rvalue,
    :doc => <<-EOS
Takes a prefix and range( start, count) and returns an array.
Examples:
produce_array_with_prefix('a',1,5)
Will return: ['a1','a2','a3','a4','a5']
EOS
) do |args|  

       raise(Puppet::ParseError, "produce_array_with_prefix(): Wrong number of arguments " +
      "given (#{args.size} for 3)") if args.size < 3
       
       prefix  = args[0] 
       start = args[1].to_i
       count = args[2].to_i
       array = (start...(start + count)).to_a
        
       retval = []
       array.each do |i|
         retval += (prefix+i.to_s).lines.to_a
       end
       return retval      
   end
end
