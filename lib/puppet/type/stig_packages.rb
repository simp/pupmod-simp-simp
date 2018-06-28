Puppet::Type.newtype(:stig_packages) do
  @doc = <<-EOM
      This type will process after the catalog has been compiled but before it
      is applied.  It takes lists of packages, one to ensure they are present
      and on to ensure they are absent.  It checks if a package
      resource exists in the catalog for the package.  If a package
      is already defined differently in the catalog print out a warning message.
      Otherwise add a resource to the catalog to manage the package.

      If warning is set to false, do not print out any warning messages.

      If mode is set to 'warning' print out a list of resources
      that would have been created.

  EOM

  def initialize(args)
    super(args)
  end

  newparam(:name) do
    desc <<-EOM
      Static name assigned to this type.
    EOM

    isnamevar

  end

  newparam(:remove) do
    desc <<-EOM
      A hash of packages to remove from the system.
    EOM

    validate do |value|
      unless value.is_a?(Hash)
        raise "Expecting a Hash for parameter remove."
      end
    end

  end

  newparam(:add) do
    desc <<-EOM
      A hash of packages to add from the system.
    EOM

    validate do |value|
      unless value.is_a?(Hash)
        raise "Expecting a Hash for parameter add."
      end
    end

  end

  newparam(:warning, :boolean => true) do
    desc <<-EOM
      If true will display warning messages.
    EOM
    newvalues(:true, :false)
    defaultto :true
  end

  newproperty(:mode) do
    desc <<-EOM
       If set to enforcing, it will remove or add the packages in the lists if
       they are not already defined in a puppet manifest.

       If set to warning it will just issue a warning if the packages are installed
       or not, again only in a manifest.
    EOM
    validate do | value|
      unless ['enforcing','warning'].include?("#{value}")
        raise(ArgumentError,"Parameter 'mode' must be either 'enforcing' or 'warning'")
      end
    end

    defaultto 'warning'

    def insync?(is)
      return true
    end
  end

  def merge_settings(pkgs,setting)
    # Merge any default settings into the options and make sure
    # ensure and name attributes are set in options hash.
    if pkgs.has_key?('defaults') and pkgs['defaults'].is_a?(Hash)
      defaults = pkgs['defaults']
    else
      defaults = {}
    end
    pkgs.delete('defaults')
    returnhash = {}
    pkgs.each { |p, opts|
      if opts.is_a?(Hash)
        options = opts.merge(defaults).merge({'ensure' => setting , 'name' => p})
      else
        options = defaults.merge({'ensure' => setting, 'name' => p})
      end
      returnhash[p] = options
    }
    returnhash
  end


  def process_list
    # Check if trying to add and remove the same package
    duppackages = @original_parameters[:remove].keys & @original_parameters[:add].keys
    unless duppackages.empty?
      raise Puppet::Error, "The following package(s) are in both the remove and add array parameters for stig_packages. #{duppackages}"
    end
    #
    # Merge the lists of packages and their options together.
    allpkgs = self.merge_settings(@original_parameters[:remove],'absent').merge(self.merge_settings(@original_parameters[:add],'present'))
    #
    #Get all the Package resources from the catalog. Munge the value of ensure to either present or absent.
    catpkg = Hash.new
    @catalog.resources.find_all{|r|
      r.is_a?(Puppet::Type.type(:package)) }.each{ |x|
        case x[:ensure]
        when :absent, :purge
          catpkg[x[:name]] = 'absent'
        else
          catpkg[x[:name]] = 'present'
        end
      }
    #
    # Go through the list of packages from the stig, check if a resource exists
    # and create resource or print message as appropriate.
    dump = allpkgs.each { |pkg, opts|
      if catpkg.has_key?(pkg)
        if opts['ensure'] != catpkg[pkg]
          @original_parameters[:warning]  && Puppet.warning("*** A Package resource for #{pkg} exists in the catalog and is set to: #{catpkg[pkg]}.  stig_packages resource expects it to be: #{opts['ensure']} It is likely this needs to be documented for STIG compliance. ***")
          Puppet.debug("Package #{pkg} is #{catpkg[pkg]} and STIG requires #{opts['ensure']}")
        end
      else
         if Puppet[:noop] || @original_parameters[:mode] == 'warning'
           Puppet.warning("Package #{pkg} with ensure #{opts['ensure']} would have been added to the system.")
         else
           catalog.create_resource('package',opts)
           Puppet.debug("Package #{pkg} with #{opts} was added to the catalog")
         end
      end
    }
    # Return nil because we don't actuall need to set an autorequire
    # resources.
    return nil
  end

  autorequire(:file) do
    # The list processing is done here to ensure that the catalog has been
    # compiled and all package definitions from manifests have been created.
    #
    self.process_list
   end

end

