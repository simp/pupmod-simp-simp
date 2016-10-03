module Puppet::Parser::Functions

  newfunction(:simp_yumrepo_gpgkeys, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Take a URL and a list of YUM servers and return a valid list of
    GPG Keys that pertain to the SIMP load.

    The string YUM_SERVER in the URL will be replaced by the found yum server
    entry.
    ENDHEREDOC

    unless args.length == 2
      raise Puppet::ParseError, ("simp_yumrepo_gpgkeys(): wrong number of arguments (#{args.length}; must be 2)")
    end
    unless args[0].is_a?(String)
      raise Puppet::ParseError, "simp_yumrepo_gpgkeys(): expects the first argument to be String, got a #{args[0].class}"
    end
    unless args[1].is_a?(Array) or args[1].is_a?(String)
      raise Puppet::ParseError, "simp_yumrepo_gpgkeys(): expects the second argument to be an array or string, got #{args[0].inspect} which is of type #{args[0].class}"
    end

    # Common GPG Keys
    gpg_keys = %w(
      RPM-GPG-KEY-puppetlabs
      RPM-GPG-KEY-SIMP
      RPM-GPG-KEY-EPEL
      RPM-GPG-KEY-elasticsearch
      RPM-GPG-KEY-grafana
    )

    case "#{Facter.value('operatingsystem')}#{Facter.value('operatingsystemmajrelease')}"
      when /(RedHat|CentOS)6/
        gpg_keys += %w(
          RPM-GPG-KEY-EPEL-6
        )
        case "#{Facter.value('operatingsystem')}"
          when /CentOS/
            gpg_keys += %w(
              RPM-GPG-KEY-CentOS-6
              RPM-GPG-KEY-CentOS-Security-6
            )
          when /RedHat/
            gpg_keys += %w(
              RPM-GPG-KEY-redhat-release
            )
        end
      when /(RedHat|CentOS)7/
        gpg_keys += %w(
          RPM-GPG-KEY-EPEL-7
        )
        case "#{Facter.value('operatingsystem')}"
          when /CentOS/
            gpg_keys += %w(
              RPM-GPG-KEY-CentOS-7
            )
          when /RedHat/
            gpg_keys += %w(
              RPM-GPG-KEY-redhat-release
            )
        end
      else
        Puppet.warning("#{Facter.value('operatingsystem')} #{Facter.value('operatingsystemmajrelease')}  support not yet complete")
    end

    toret = []
    Array(args[1]).each do |yumsvr|
      yum_base = args[0].gsub('YUM_SERVER',yumsvr)
      toret << gpg_keys.map{|x| x = "#{yum_base}/GPGKEYS/#{x}"}
    end

    toret.flatten.join("\n    ")

  end
end
