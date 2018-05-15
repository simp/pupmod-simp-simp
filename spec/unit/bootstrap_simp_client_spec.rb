# Cannot 'require' bootstrap_simp_client Ruby file, because it is missing
# the '.rb' suffix.  So, use a symlink to it that has the '.rb' suffix.
# This symlink is in the tests directory.
$: << File.expand_path(File.join(File.dirname(__FILE__), '..','..','tests'))
require 'bootstrap_simp_client'

require 'spec_helper'
require 'tmpdir'

describe 'BootstrapSimpClient' do

  let(:bootstrap) { BootstrapSimpClient.new }

  let(:success_result) {{
    :exitstatus => 0,
    :stdout => '',
    :stderr => ''
  }}

  before :each do
    @tmp_dir = Dir.mktmpdir( File.basename( __FILE__ ) )
    @puppet_conf_file = File.join(@tmp_dir, 'puppet.conf')
    @log_file = File.join(@tmp_dir, 'bootstrap.log')
    @env_file = File.join(@tmp_dir, 'env')
    @test_args = [
      '-s', 'puppet.test.local',
      '-c', 'puppetca.test.local',
      '-C', @puppet_conf_file,
      '-l', @log_file,
      '-e', @env_file,
      '-q'
    ]
    @non_quiet_test_args = @test_args.dup
    @non_quiet_test_args.delete_if { |x| x == '-q' }

    # Need to make sure we have something to find
    FileUtils.touch(@puppet_conf_file)
    ENV['LOCKED'] = nil
  end

  after :each do
    FileUtils.remove_entry_secure(@tmp_dir) if @tmp_dir
  end

  describe '#bootstrap_locked?' do

    it 'returns false when LOCKED environment variable does not exist' do
      bootstrap.parse_command_line(@test_args)
      expect( bootstrap.bootstrap_locked? ).to be false
    end

    it "returns false when LOCKED environment variable is 'false'" do
      bootstrap.parse_command_line(@test_args)
      ENV['LOCKED'] = 'false'
      expect( bootstrap.bootstrap_locked? ).to be false
    end

    it "returns true when LOCKED environment variable is 'true'" do
      bootstrap.parse_command_line(@test_args)
      ENV['LOCKED'] = 'true'
      expect( bootstrap.bootstrap_locked? ).to be true
    end
  end

  describe '#configure_puppet' do
    it 'creates puppet config file' do
      bootstrap.parse_command_line(@test_args)
      bootstrap.configure_puppet
      expected = <<EOM
[main]
vardir            = /opt/puppetlabs/puppet/cache
classfile         = $vardir/classes.txt
localconfig       = $vardir/localconfig
logdir            = /var/log/puppetlabs/puppet
report            = false
rundir            = /var/run/puppetlabs
server            = puppet.test.local
ssldir            = /etc/puppetlabs/puppet/ssl
trusted_node_data = true
stringify_facts   = false
digest_algorithm  = sha256
keylength         = 4096
ca_server         = puppetca.test.local
ca_port           = 8141
EOM
      expect( File.exist?(@puppet_conf_file) ).to be true
      expect( File.read(@puppet_conf_file) ).to eq expected
    end
  end

  describe '#execute' do
    it 'returns appropriate results when command succeeeds' do
      bootstrap.parse_command_line(@test_args)
      command = "ls #{__FILE__}"
      expect( bootstrap.execute(command)[:exitstatus] ).to eq 0
      expect( bootstrap.execute(command)[:stdout] ).to match "#{__FILE__}"
      expect( bootstrap.execute(command)[:stderr] ).to eq ''
    end

    it 'returns appropriate results when command fails' do
      bootstrap.parse_command_line(@test_args)
      command = 'ls /some/missing/path1 /some/missing/path2'
      expect( bootstrap.execute(command)[:exitstatus] ).to_not eq 0
      expect( bootstrap.execute(command)[:stdout] ).to eq ''
      expect( bootstrap.execute(command)[:stderr] ).to match /ls: cannot access.*\/some\/missing\/path1.*: No such file or directory/
    end
  end

  describe '#fix_file_contexts' do
    it 'does not execute fixfiles when selinux is not installed' do
      Facter.stubs(:value).with(:selinux).returns(false)
      bootstrap.stubs(:execute).with("fixfiles -l #{@log_file} -f relabel").returns({
        :exitstatus => -1,
        :stdout => '',
        :stderr => 'some fixfile error'})
      bootstrap.parse_command_line(@test_args)

      # if we try to run fixfiles, this will fail
      bootstrap.fix_file_contexts
    end

    it 'does not execute fixfiles when selinux mode is disabled' do
      Facter.stubs(:value).with(:selinux).returns(true)
      Facter.stubs(:value).with(:selinux_current_mode).returns('disabled')
      bootstrap.stubs(:execute).with("fixfiles -l #{@log_file} -f relabel").returns({
        :exitstatus => -1,
        :stdout => '',
        :stderr => 'some fixfile error'})
      bootstrap.parse_command_line(@test_args)

      # if we try to run fixfiles, this will fail
      bootstrap.fix_file_contexts
    end

    it 'executes fixfiles when selinux mode is not disabled' do
      Facter.stubs(:value).with(:selinux).returns(true)
      Facter.stubs(:value).with(:selinux_current_mode).returns('enforcing')
      bootstrap.stubs(:execute).with("fixfiles -l #{@log_file} -f relabel").returns(success_result)
      bootstrap.parse_command_line(@test_args)

      # success means nothing is raised
      bootstrap.fix_file_contexts
    end

    it 'fail when fixfiles fails' do
      Facter.stubs(:value).with(:selinux).returns(true)
      Facter.stubs(:value).with(:selinux_current_mode).returns('permissive')
      bootstrap.stubs(:execute).with("fixfiles -l #{@log_file} -f relabel").returns({
        :exitstatus => -1,
        :stdout => '',
        :stderr => 'some fixfile error'})
      bootstrap.parse_command_line(@test_args)

      expect { bootstrap.fix_file_contexts }.to raise_error(RuntimeError)
    end
  end

  describe '#get_retry_interval' do
    it 'returns initial value upon first execution' do
      bootstrap.parse_command_line(@test_args)
      expect( bootstrap.get_retry_interval ).to eq BootstrapSimpClient::DEFAULT_INITIAL_RETRY_SECONDS
    end

    it 'returns value multiplied by factor upon subsequent executions' do
      bootstrap.parse_command_line(@test_args)
      bootstrap.get_retry_interval
      expected = BootstrapSimpClient::DEFAULT_INITIAL_RETRY_SECONDS*BootstrapSimpClient::DEFAULT_RETRY_FACTOR
      expected = expected.round
      expect( bootstrap.get_retry_interval ).to eq expected

      expected *= BootstrapSimpClient::DEFAULT_RETRY_FACTOR
      expected = expected.round
      expect( bootstrap.get_retry_interval ).to eq expected
    end
  end

  describe '#not_nil_or_empty?' do
    it 'returns initial value upon first execution' do
      expect( bootstrap.not_nil_or_empty?('not empty') ).to be true
      expect( bootstrap.not_nil_or_empty?(['not', 'empty']) ).to be true
      expect( bootstrap.not_nil_or_empty?({'not' => 'empty'}) ).to be true
      expect( bootstrap.not_nil_or_empty?(nil) ).to be false
      expect( bootstrap.not_nil_or_empty?('') ).to be false
      expect( bootstrap.not_nil_or_empty?([]) ).to be false
      expect( bootstrap.not_nil_or_empty?({}) ).to be false
    end
  end

  # will also test validate_options here
  describe '#parse_command_line' do
    it 'uses defaults when only required options are specified' do
      File.stubs(:exist?).returns(true)
      test_args = [ '-s', 'puppet.test.local', '-c', 'puppetca.test.local']
      bootstrap.parse_command_line(test_args)

      cmd = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            ' --no-show_diff --no-splay --verbose --logdest' +
            ' /root/puppet.bootstrap.log --waitforcert 10 --evaltrace' +
            ' --summarize'

      expected = {
        :bootstrap_service      => BootstrapSimpClient::DEFAULT_BOOTSTRAP_SERVICE,
        :service_env_file       => File.join(BootstrapSimpClient::DEFAULT_SERVICE_CONFIG_DIR,
                                   BootstrapSimpClient::DEFAULT_BOOTSTRAP_SERVICE),
        :set_static_hostname    => false,
        :ntp_servers            => [],
        :puppet_conf_file       => BootstrapSimpClient::DEFAULT_PUPPET_CONF_FILE,
        :digest_algorithm       => BootstrapSimpClient::DEFAULT_DIGEST_ALGORITHM,
        :puppet_keylength       => BootstrapSimpClient::DEFAULT_PUPPET_KEYLENGTH,
        :puppet_ca_port         => BootstrapSimpClient::DEFAULT_PUPPET_CA_PORT,
        :puppet_wait_for_cert   => BootstrapSimpClient::DEFAULT_PUPPET_WAIT_FOR_CERT,
        :print_stats            => BootstrapSimpClient::DEFAULT_PRINT_STATS,
        :num_puppet_runs        => BootstrapSimpClient::DEFAULT_NUM_PUPPET_RUNS,
        :initial_retry_interval => BootstrapSimpClient::DEFAULT_INITIAL_RETRY_SECONDS,
        :retry_factor           => BootstrapSimpClient::DEFAULT_RETRY_FACTOR,
        :max_seconds            => BootstrapSimpClient::DEFAULT_MAX_SECONDS,
        :log_file               => BootstrapSimpClient::DEFAULT_LOG_FILE,
        :quiet                  => BootstrapSimpClient::DEFAULT_QUIET,
        :debug                  => BootstrapSimpClient::DEFAULT_DEBUG,
        :help_requested         => false,
        :puppet_server          => 'puppet.test.local',
        :puppet_ca              => 'puppetca.test.local',
        :puppet_cmd             => cmd
      }
      expect( bootstrap.options ).to eq expected
    end

    it 'uses configured options when non-conflicting options are specified' do
      File.stubs(:exist?).returns(true)
      test_args = [
        '-s', 'puppet.test.local',
        '-c', 'puppetca.test.local',
        '-a', 'sha512',
        '-k', '2048',
        '-H',
        '-n', 'ntp1.test.local,ntp2.test.local',
        '-p', '8240',
        '-r', '3',
        '-i', '30',
        '-f', '2.5',
        '-m', '3600',
        '--no-print-stats',
        '-w', '20',
        '-C', @puppet_conf_file,
        '-N', 'my_bootstrap',
        '-e', '/opt/sysconfig/my_bootstrap',
        '-l', 'mylog.txt',
        '-d'
      ]
      bootstrap.parse_command_line(test_args)

      cmd = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            ' --no-show_diff --no-splay --verbose --logdest' +
            ' mylog.txt --waitforcert 20'

      expected = {
        :bootstrap_service      => 'my_bootstrap',
        :service_env_file       => '/opt/sysconfig/my_bootstrap',
        :set_static_hostname    => true,
        :ntp_servers            => [ 'ntp1.test.local', 'ntp2.test.local'],
        :puppet_conf_file       => @puppet_conf_file,
        :digest_algorithm       => 'sha512',
        :puppet_keylength       => 2048,
        :puppet_ca_port         => 8240,
        :puppet_wait_for_cert   => 20,
        :print_stats            => false,
        :num_puppet_runs        => 3,
        :initial_retry_interval => 30,
        :retry_factor           => 2.5,
        :max_seconds            => 3600,
        :log_file               => 'mylog.txt',
        :quiet                  => BootstrapSimpClient::DEFAULT_QUIET,
        :debug                  => true,
        :help_requested         => false,
        :puppet_server          => 'puppet.test.local',
        :puppet_ca              => 'puppetca.test.local',
        :puppet_cmd             => cmd
      }
      expect( bootstrap.options ).to eq expected
    end

    it 'fails if options fail validation' do
      expect { bootstrap.parse_command_line([]) }.to raise_error(RuntimeError)
    end

    it 'fails if unknown options is specified' do
      expect { bootstrap.parse_command_line(['--oops']) }.to raise_error(RuntimeError)
    end

    it 'prints help when --help option specified' do
      expect { bootstrap.parse_command_line([ '-h' ]) }.to output(
        /Usage: bootstrap_simp_client.rb -s PUPPETSRV -c PUPPETCA \[options\]/).
        to_stdout
    end
  end

  describe '#reset_retry_interval' do
    it 'returns configured initial value upon execution' do
      bootstrap.parse_command_line(@test_args)
      bootstrap.get_retry_interval
      bootstrap.get_retry_interval
      bootstrap.reset_retry_interval
      expect( bootstrap.get_retry_interval ).to eq BootstrapSimpClient::DEFAULT_INITIAL_RETRY_SECONDS
    end
  end

  describe '#run' do
    it 'prints help when --help option specified' do
      expect( bootstrap.run([ '--help' ] ) ).to eq 0
      expect { bootstrap.run([ '-h' ]) }.to output(
        /Usage: bootstrap_simp_client.rb -s PUPPETSRV -c PUPPETCA \[options\]/).
        to_stdout
    end

    it 'returns 0 when processing succeeds' do
      bootstrap.stubs(:execute).with('/usr/sbin/ntpdate -b ntpserver1 ntpserver2').returns(success_result)
      puppet_cmd1 = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize --tags pupmod,simp'
      bootstrap.stubs(:execute).with(puppet_cmd1).returns(success_result)

      puppet_cmd2 = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize '
      bootstrap.stubs(:execute).with(puppet_cmd2).returns(success_result)

      Facter.stubs(:value).with(:selinux).returns(true)
      Facter.stubs(:value).with(:selinux_current_mode).returns('enforcing')
      bootstrap.stubs(:execute).with("fixfiles -l #{@log_file} -f relabel").returns(success_result)

      bootstrap.stubs(:execute).with('puppet resource service simp_client_bootstrap enable=false').returns(success_result)
      bootstrap.stubs(:execute).with('puppet resource service puppet enable=true').returns(success_result)

      expect( bootstrap.run(@test_args + [ '-n', 'ntpserver1,ntpserver2' ]) ).to eq 0

      # detailed actions are unit tested in other examples, so here only
      # check for log messages to indicate the methods that executed
      # the actions were called
      log = File.read(@log_file)
      expect( log ).to match(/Setting up system for Puppet bootstrap/)
      expect( log ).to match(/Setting puppet configuration/)
      expect( log ).to match(/Setting the system time against ntpserver1 ntpserver2/)
      expect( log ).to match(/Running Puppet bootstrap/)
      expect( log ).to match(/Initial puppet agent run with pupmod,simp tags/)
      expect( log ).to match(/Relabeling filesystem for selinux/)
      expect( log ).to match(/1 of 2 puppet agent runs/)
      expect( log ).to match(/2 of 2 puppet agent runs/)
      expect( log ).to match(/Puppet bootstrap successfully completed/)
     end

     it 'runs configured number of puppet agent runs' do
      puppet_cmd1 = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize --tags pupmod,simp'
      bootstrap.stubs(:execute).with(puppet_cmd1).returns(success_result)

      puppet_cmd2 = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize '
      bootstrap.stubs(:execute).with(puppet_cmd2).returns(success_result)
      Facter.stubs(:value).with(:selinux).returns(false)

      bootstrap.stubs(:execute).with('puppet resource service simp_client_bootstrap enable=false').returns(success_result)
      bootstrap.stubs(:execute).with('puppet resource service puppet enable=true').returns(success_result)

      expect( bootstrap.run(@test_args + [ '-r', '4' ]) ).to eq 0

      log = File.read(@log_file)
      expect( log ).to match(/1 of 4 puppet agent runs/)
      expect( log ).to match(/2 of 4 puppet agent runs/)
      expect( log ).to match(/3 of 4 puppet agent runs/)
      expect( log ).to match(/4 of 4 puppet agent runs/)
     end

     it 'returns 1 when command line options fail validation' do
       expect( bootstrap.run([]) ).to eq 1
     end

     it 'returns 1 when fixfiles fails' do
      puppet_cmd1 = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize --tags pupmod,simp'
      bootstrap.stubs(:execute).with(puppet_cmd1).returns(success_result)

      puppet_cmd2 = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize '
      bootstrap.stubs(:execute).with(puppet_cmd2).returns(success_result)

      Facter.stubs(:value).with(:selinux).returns(true)
      Facter.stubs(:value).with(:selinux_current_mode).returns('enforcing')
      bootstrap.stubs(:execute).with("fixfiles -l #{@log_file} -f relabel").returns({
        :exitstatus => -1,
        :stdout => '',
        :stderr => 'some fixfile error'})

      expect( bootstrap.run(@test_args) ).to eq 1
      log = File.read(@log_file)
      expect( log ).to match(/ERROR: fixfiles failed with -1 exit status/)
      expect( log ).to_not match(/1 of 2 puppet agent runs/)
      expect( log ).to_not match(/2 of 2 puppet agent runs/)
      expect( log ).to_not match(/Puppet bootstrap successfully completed/)
     end

     it 'returns 1 when processing times out' do
      puppet_cmd = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize --tags pupmod,simp'
      bootstrap.stubs(:execute).with(puppet_cmd).returns({
        :exitstatus => 1,
        :stdout => '',
        :stderr => "Could not request certificate: The certificate retrieved from the master does not match the agent's private key."
      })

      expect( bootstrap.run(@test_args + [ '-i', '1', '-m', '2' ]) ).to eq 1
      log = File.read(@log_file)
      expect( log ).to match(/Initial puppet agent run with pupmod,simp tags/)
      expect( log ).to match(/Could not request certificate/)
      expect( log ).to match(/>>>>>> Command failed.  Retrying in 1 seconds/)
      expect( log ).to match(/>>>>>> Command failed.  Retrying in 2 seconds/)
      expect( log ).to match(/ERROR: Failed to complete Puppet bootstrap within 2 seconds/)
     end
  end

  describe '#run_puppet_agent' do

    it 'executes the puppet agent command' do
      cmd = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize '
      bootstrap.stubs(:execute).with(cmd).returns(success_result)
      bootstrap.parse_command_line(@test_args)
      bootstrap.run_puppet_agent
      expect( File.read(@log_file) ).to match(/puppet agent run/)
    end

    it 'executes the puppet agent command with extra arguments' do
      cmd = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize --tags pupmod,simp'
      bootstrap.stubs(:execute).with(cmd).returns(success_result)
      bootstrap.parse_command_line(@test_args)
      bootstrap.run_puppet_agent('--tags pupmod,simp', 'tagged run')
      expect( File.read(@log_file) ).to match(/tagged run/)
    end

    it 'when puppet agent command fails, retries until it succeeds' do
      failed_result = {
        :exitstatus => 1,
        :stdout => '',
        :stderr => 'some puppet agent error'
      }

      cmd = '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize' +
            " --no-show_diff --no-splay --verbose --logdest #{@log_file}" +
            ' --waitforcert 10 --evaltrace --summarize '
      results = [failed_result, failed_result, success_result]
      bootstrap.stubs(:execute).with(cmd).returns(*results)
      bootstrap.parse_command_line(@test_args + ['-i', '1'])
      bootstrap.run_puppet_agent
      log = File.read(@log_file)
      expect( log ).to match(/\(info\): puppet agent run/)
      expect( log ).to match(/\(err\): some puppet agent error/)
      expect( log ).to match(/\(debug\): >>>>>> Command failed.  Retrying in 1 seconds/)
      expect( log ).to match(/\(debug\): >>>>>> Command failed.  Retrying in 2 seconds/)
    end
  end

  describe '#set_static_hostname' do
    it 'when enabled and valid hostname is set it runs hostnamectl' do
      File.stubs(:exist?).returns(true)
      bootstrap.stubs(:execute).with('/usr/bin/hostname -f').returns({
        :exitstatus => 0,
        :stdout => 'client1.test.local',
        :stderr => ''})

      bootstrap.stubs(:execute).with('/usr/bin/hostnamectl set-hostname --static client1.test.local').returns({
        :exitstatus => 1,
        :stdout => '',
        :stderr => 'Could not set property: Connection timed out'})

      bootstrap.parse_command_line(@test_args + [ '-H' ])
      bootstrap.set_static_hostname
    end

    it "fails if 'hostname -f' returns an empty string" do
      File.stubs(:exist?).returns(true)
      bootstrap.stubs(:execute).with('/usr/bin/hostname -f').returns({
        :exitstatus => 1,
        :stdout => '',
        :stderr => ''})

      bootstrap.parse_command_line(@test_args + [ '-H' ])
      expect { bootstrap.set_static_hostname }.to raise_error(/Cannot set static hostname: '' is not a valid hostname/)
    end

    it "fails if 'hostname -f' returns 'localhost.localdomain'" do
      File.stubs(:exist?).returns(true)
      bootstrap.stubs(:execute).with('/usr/bin/hostname -f').returns({
        :exitstatus => 0,
        :stdout => 'localhost.localdomain',
        :stderr => ''})

      bootstrap.parse_command_line(@test_args + [ '-H' ])
      expect { bootstrap.set_static_hostname }.to raise_error(/Cannot set static hostname: 'localhost.localdomain' is not a valid hostname/)
    end
  end

  describe '#set_system_time' do
    it 'does nothing if no ntp servers are configured' do
      bootstrap.stubs(:execute).returns({
        :exitstatus => -1,
        :stdout => '',
        :stderr => 'some ntpdate error'})
      bootstrap.parse_command_line(@test_args)

      # if we try to run ntdpdate, this will fail
      bootstrap.set_system_time
    end

    it 'when ntp servers are configured it runs ntpdate' do
      bootstrap.stubs(:execute).with('/usr/sbin/ntpdate -b ntpserver1 ntpserver2').returns(success_result)
      bootstrap.parse_command_line(@test_args + [ '-n', 'ntpserver1,ntpserver2' ])
      bootstrap.set_system_time
    end

    it 'logs error when ntpdate fails' do
      bootstrap.stubs(:execute).with('/usr/sbin/ntpdate -b ntpserver1 ntpserver2').returns({
        :exitstatus => -1,
        :stdout => '',
        :stderr => 'some ntpdate error'})
      bootstrap.parse_command_line(@test_args + [ '-n', 'ntpserver1,ntpserver2' ])
      bootstrap.set_system_time
      expect( File.read(@log_file) ).to match(/\(warning\): some ntpdate error/)
    end
  end

  describe '#set_up_log' do
    it 'creates log file for this run' do
      bootstrap.parse_command_line(@test_args)
      bootstrap.set_up_log
      expect( File.exist?(@log_file) ).to be true
    end

    it 'backs up existing log' do
      FileUtils.touch(@log_file, :mtime => Time.new(2017, 1, 13, 11, 42, 3))
      bootstrap.parse_command_line(@test_args)
      bootstrap.set_up_log
      backup = "#{@log_file}.2017-01-13T114203"
      expect( File.exist?(backup) ).to be true
      expect( File.exist?(@log_file) ).to be true
    end
  end

  # test using parse_command_line
  describe '#validate_options' do
    it 'fails if the puppet config file does not already exist' do
      bad_test_args = @test_args.map do |x|
        x == @puppet_conf_file ? "#{@puppet_conf_file}.d/#{@puppet_conf_file}" : x
      end
      expect { bootstrap.parse_command_line(bad_test_args) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /Could not find puppet\.conf/)
    end

    it 'fails when puppet server is not specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line([]) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /No Puppet server specified/)
    end

    it 'fails when puppet CA is not specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line(['-s', 'puppet.test.local']) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /No Puppet CA specified/)
    end

    it 'fails when invalid puppet CA port is specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line(@test_args + ['-p', '65536']) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /Invalid Puppet CA port '65536': /)
    end

    it 'fails when invalid number of puppet agent runs is specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line(@test_args + ['-r', '0']) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /Invalid number of puppet agent runs '0': /)
    end

    it 'fails when invalid puppet keylength is specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line(@test_args + ['-k', '0']) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /Invalid Puppet keylength '0': /)
    end

    it 'fails when invalid puppet wait for cert is specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line(@test_args + ['-w', '-10']) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /Invalid Puppet wait for cert '-10': /)
    end

    it 'fails when invalid initial retry interval is specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line(@test_args + ['-i', '0']) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /Invalid initial retry interval '0': /)
    end

    it 'fails when invalid retry factor is specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line(@test_args + ['-f', '0']) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /Invalid retry factor '0.0': /)
    end

    it 'fails when invalid max seconds is specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line(@test_args + ['-m', '0']) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /Invalid max seconds '0': /)
    end

    it 'fails when both --quiet and --debug are specified' do
      File.stubs(:exist?).returns(true)
      expect { bootstrap.parse_command_line(@test_args + ['--quiet', '--debug']) }.to raise_error(
        BootstrapSimpClient::ConfigurationError, /--quiet and --debug cannot be used together/)
    end
  end

  describe '#title' do
    it 'formats level 1 titles' do
      expect( bootstrap.title('Level 0',0) ).to eq 'Level 0'
      expect( bootstrap.title('Level 1',1) ).to eq '*** Level 1 ***'
      expect( bootstrap.title('Level 2',2) ).to eq '------ Level 2 ------'
      expect( bootstrap.title('Level 3',3) ).to eq '......... Level 3 .........'
      expect( bootstrap.title('Level 4',4) ).to eq 'Level 4'
    end
  end

  describe '#error' do
    it "writes to log with 'err' level and to stderr, pre-pending with blank line" do
      bootstrap.parse_command_line(@non_quiet_test_args)
      message = 'This is an error message'
      expect { bootstrap.error(message) }.to output("\n#{message}\n").to_stderr
      expect( File.read(@log_file) ).to match(/\(err\): #{message}/)
    end

    it 'suppresses empty error messages' do
      bootstrap.parse_command_line(@non_quiet_test_args)
      expect { bootstrap.error('') }.to_not output.to_stderr
      # haven't run set_up_log or appended to the log, so the
      # file will not exist
      expect( File.exist?(@log_file) ).to be false
    end
  end

  describe '#warn' do
    it "writes to log with 'warning' level and to stdout" do
      bootstrap.parse_command_line(@non_quiet_test_args)
      message = 'This is an warn message'
      expect { bootstrap.warn(message) }.to output("#{message}\n").to_stdout
      expect( File.read(@log_file) ).to match(/\(warning\): #{message}/)
    end

    it 'suppresses empty warning messages' do
      bootstrap.parse_command_line(@non_quiet_test_args)
      expect { bootstrap.warn('') }.to_not output.to_stdout
      # haven't run set_up_log or appended to the log, so the
      # file will not exist
      expect( File.exist?(@log_file) ).to be false
    end
  end

  describe '#info' do
    it "writes to log with 'info' level and to stdout" do
      bootstrap.parse_command_line(@non_quiet_test_args)
      message = 'This is an info message'
      expect { bootstrap.info(message) }.to output("#{message}\n").to_stdout
      expect( File.read(@log_file) ).to match(/\(info\): #{message}/)
    end

    it 'does not suppress empty info messages' do
      bootstrap.parse_command_line(@non_quiet_test_args)
      expect { bootstrap.info('') }.to output("\n").to_stdout
      expect( File.read(@log_file) ).to match(/\(info\): \n/)
    end
  end

  describe '#debug' do
    it "writes to log with 'debug' level and to stdout when --debug specified" do
      bootstrap.parse_command_line(@non_quiet_test_args + ['-d'])
      message = 'This is an debug message'
      expect { bootstrap.debug(message) }.to output("#{message}\n").to_stdout
      expect( File.read(@log_file) ).to match(/\(debug\): #{message}/)
    end

    it "writes to log with 'debug' level, only, when --debug is not specified" do
      bootstrap.parse_command_line(@non_quiet_test_args)
      message = 'This is an debug message'
      expect { bootstrap.debug(message) }.to_not output.to_stdout
      expect( File.read(@log_file) ).to match(/\(debug\): #{message}/)
    end

    it 'does not suppress empty debug messages' do
      bootstrap.parse_command_line(@non_quiet_test_args + ['-d'])
      expect { bootstrap.debug('') }.to output("\n").to_stdout
      expect( File.read(@log_file) ).to match(/\(debug\): \n/)
    end
  end

  describe '#log' do
    # rest of functionality is completely tested by the other log methods
    it 'prepends message with a timestamp and process id' do
      bootstrap.parse_command_line(@test_args)
      Time.stubs(:now).returns(Time.new(2017, 1, 13, 11, 42, 3, '-05:00'))
      bootstrap.info('This is an info message')
      expected = "2017-01-13 11:42:03 -0500 bootstrap_simp_client.rb (info): This is an info message\n"
      expect( File.read(@log_file) ).to eq expected
    end

    it 'logs array input in one message with embedded newlines' do
      bootstrap.parse_command_line(@test_args)
      Time.stubs(:now).returns(Time.new(2017, 1, 13, 11, 42, 3, '-05:00'))
      bootstrap.info(['message1', 'message2'])
      expected = "2017-01-13 11:42:03 -0500 bootstrap_simp_client.rb (info): message1\nmessage2\n"
      expect( File.read(@log_file) ).to eq expected
    end

    it 'suppresses console out while still writing to the log, when --quiet specified' do
      bootstrap.parse_command_line(@test_args)
      expect { bootstrap.error('error message') }.to_not output.to_stderr
      expect { bootstrap.warn('warn message') }.to_not output.to_stdout
    end

    it 'fails when it cannot write to the log file' do
      test_args = @test_args.map do |x|
        x == @log_file ? "#{@tmp_dir}/logs/#{@log_file}" : x
      end
      bootstrap.parse_command_line(test_args)
      expect { bootstrap.info('info message') }.to raise_error(Errno::ENOENT)
    end
  end
end
