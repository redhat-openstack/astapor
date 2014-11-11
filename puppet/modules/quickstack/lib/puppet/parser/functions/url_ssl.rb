module Puppet::Parser::Functions
    newfunction(:url_ssl, :type => :rvalue, :doc => <<-EOS
Returns url for ssl CA if CA certificate provided
EOS
) do |arguments|
    Puppet::Parser::Functions.autoloader.loadall
    raise(Puppet::ParseError, "url_ssl(): Wrong number of arguments " +
      "given (#{arguments.size} for 2)") if arguments.size < 2

    ssl    = arguments[0] ||= false
    ssl_ca = arguments[1] ||= ''

    if ssl
      if ssl_ca != ''
        "?ssl_ca=#{ssl_ca}"
      else
        raise(Puppet::ParseError, "url_ssl(): No CA certificate for SSL mode")
      end
    else
      ''
    end
  end
end
