Puppet::Type.newtype(:stig_packages) do
  @doc = <<-EOM
      Pass in list of packages to be installed or removed but first
      check if they were already defined in the catalog.  If they
      were then just print out a message.

      This makes sure it will not interfer with packages defined in the
      Puppet manifests.
  EOM

  def initialize(args)
    super(args)
  end

#  def self.merge_defaults(pkghash, ensurevalue)
#    # merge the default settings here or
#    # that an be done using nicks code in the
#    # gnome module before the call.
#    if pkghash.has_key?['defaults'] and pkghash['defaults'].is_a?(Hash)
#      defaults = pkghash['defaults']
#    else
#      defaults = {}
#    end
#    pkghash.delete['defaults#']
#    ensure_setting = { 'ensure' => ensurevalue }
#    returnhash = {}
#    pkghash.each { |p, opts|
#      options = opts.merge(defaults).merge({'ensure' => ensurevalue})
#      returnhash[p] = options
#    }
#    returnhash
#  end


  newparam(:name) do
    desc <<-EOM
      static name assigned to this type. You can only declare
      this type of resource once in your node scope.
    EOM

    isnamevar

    defaultto 'svckill'

    validate do |value|
      raise(ArgumentError,"Error: $name must be 'stig_packages'.") unless value == 'stig_packages'
    end
  end

  newparam(:remove) do
    desc <<-EOM
      a hash of packages to remove from the system.
    EOM

    validate do |value|
      unless value.is_a?(Hash)
        raise "Expecting a Hash for parameter remove"
      end
    end

    munge do |value|
      require 'pry'
      if value.is_a?(Hash)
        if value.has_key?('defaults') and value['defaults'].is_a?(Hash)
          defaults = value['defaults']
        else
          defaults = {}
        end
        value.delete('defaults')
        returnhash = {}
        binding.pry
        value.each { |p, opts|
          if opts.is_a?(Hash)
            options = opts.merge(defaults).merge({'ensure' => 'absent', 'name' => p})
          else
            options = defaults.merge({'ensure' => 'absent', 'name' => p})
          end
          returnhash[p] = options
        }
        binding.pry
        value = returnhash
        binding.pry
      end
    end
  end

  newparam(:add) do
    desc <<-EOM
      a hash of packages to add from the system.
    EOM

    validate do |value|
      require 'pry'
      binding.pry
      unless value.is_a?(Hash)
        raise "Expecting a Hash for parameter add"
      end
    end

    munge do |value|
      require 'pry'
      if value.is_a?(Hash)
        if value.has_key?('defaults') and value['defaults'].is_a?(Hash)
          defaults = value['defaults']
        else
          defaults = {}
        end
        value.delete('defaults')
        returnhash = {}
        binding.pry
        value.each { |p, opts|
          if opts.is_a?(Hash)
            options = opts.merge(defaults).merge({'ensure' => 'present', 'name' => p})
          else
            options = defaults.merge({'ensure' => 'present', 'name' => p})
          end
          returnhash[p] = options
        }
        binding.pry
        value = returnhash
      end
    end

  end

  newparam(:warnings) do
    desc <<-EOM
      If true will display warning messages for packages that are managed.
    EOM
    munge do |value|
      case value
      when true, :true, 'true', :yes, 'yes'
        :true
      when false, :false, 'false', :no, 'no'
        :false
      # Messages Only a puppet definition conflicts.  Many of the
        # must haves are already included and would show up as a warning otherwise.
      when :conflict, 'conflict'
        :conflict
      else
        raise('expected a boolean value or :conflict')
      end
    end
    defaultto :true 
  end

#  newproperty(:mode) do
  newparam(:mode) do
    #???? Do I need this?
    desc <<-EOM
       If set to enforcing, it will remove or add the packages in the lists if
       they are not already defined in a puppet manifest.

       If set to warning it will just issue a warning if the packages are installed
       or not, again only in a manifest.
    EOM
    validate do | value|
      unless ['enforcing','warning'].include?("#{value}")
        raise(ArgumentError,"'ensure' must be either 'enforcing' or 'warning'")
      end
    end

#    def insync?(is)
#      self.check_packages
#    end
  end

  autorequire(:smurfdom) do
    require 'pry'
    binding.pry
    # search the catalog here for  package and then create the package resource and add to catalog.
    allpkgs = @resource[:remove].merge(@resource[:add])
    #Note: If there is a key for both remove and add that will add them.  maybe check for dups?
    allpkgs.each { |pkg, opts|
      opts[:name] = pkg
      @resource.catalog.create_resource('package', opts)
    }



  end

end
