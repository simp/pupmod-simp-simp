module Puppet::Parser::Functions

  newfunction(:simp_yumrepo_mangle, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Take a URL and a list of YUM servers and return a valid list of
    repositories for a baseurl entry with appropriate spacing.

    The string YUM_SERVER in the URL will be replaced by the found yum server
    entry.

    Example:

    simp_yumrepo_mangle('http://YUM_SERVER/yum/repo',['yum1.domain','yum2.domain'])

    Returns:

    "http://yum1.domain/yum/repo\n    http://yum2.domain/yum/repo"
    ENDHEREDOC

    unless args.length == 2
      raise Puppet::ParseError, ("simp_yumrepo_mangle(): wrong number of arguments (#{args.length}; must be 2)")
    end
    unless args[0].is_a?(String)
      raise Puppet::ParseError, "simp_yumrepo_mangle(): expects the first argument to be String, got a #{args[0].class}"
    end
    unless args[1].is_a?(Array) or args[1].is_a?(String)
      raise Puppet::ParseError, "simp_yumrepo_mangle(): expects the second argument to be an array or string, got #{args[0].inspect} which is of type #{args[0].class}"
    end

    toret = []
    Array(args[1]).each do |hname|
      toret << args[0].gsub('YUM_SERVER',hname)
    end

    toret.join("\n    ")

  end

end
