# Combine all the cloud based facts and determine where this
#  code is being run
# Combines:
# * cloud
# * ec2_metadata
# * hypervisor
# * gce
# * xen
Facter.add('simp_cloud') do
  cloud        =  Facter.value('cloud')
  hypervisors  = (Facter.value('hypervisors')||{}).keys
  ec2_metadata = !Facter.value('ec2_metadata').nil?
  gce          = !Facter.value('gce').nil?
  xen          = !Facter.value('xen').nil?
  vagrant      = !Facter.value('vagrant').nil?

  setcode do
    if cloud
      cloud['provider']
    elsif ec2_metadata
      'amazon'
    elsif gce
      'gce'
    elsif xen
      'xen'
    elsif vagrant
      'vagrant'
    else
      hypervisors.first
    end
  end
end
