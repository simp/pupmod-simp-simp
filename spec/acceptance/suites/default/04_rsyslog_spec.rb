require 'spec_helper_acceptance'

test_name 'simp rsyslog stock classes'

describe 'simp rsyslog stock classes' do

  let(:servers) { hosts_with_role( hosts, 'rsyslog_server' ) }

  let(:log_server_manifest) {
    <<-EOS
      include 'simp::rsyslog::stock'
    EOS
  }
  let(:log_server_hieradata) {
    <<-EOS
---
simp::rsyslog::stock::is_server: true
simp::rsyslog::stock::log_server::use_iptables: true
simp::rsyslog::stock::log_server::client_nets: 'any'
compliance_map :
  test_policy :
    test::var1 :
      'identifiers' :
        - 'TEST_POLICY1'
      'value' : 'test1'

    EOS
  }
  let(:log_server_disable01_hieradata) {
    <<-EOS
#{log_server_hieradata}
simp::rsyslog::stock::log_server::use_default_sudosh_rules: false
simp::rsyslog::stock::log_server::use_default_httpd_rules: false
simp::rsyslog::stock::log_server::use_default_dcpd_rules: false
simp::rsyslog::stock::log_server::use_default_puppet_agent_rules: false
simp::rsyslog::stock::log_server::use_default_puppet_master_rules: false
simp::rsyslog::stock::log_server::use_default_audit_rules: false
simp::rsyslog::stock::log_server::use_default_slapd_rules: false
simp::rsyslog::stock::log_server::use_default_kern_rules: false
simp::rsyslog::stock::log_server::use_default_mail_rules: false
simp::rsyslog::stock::log_server::use_default_cron_rules: false
simp::rsyslog::stock::log_server::use_default_emerg_rules: false
simp::rsyslog::stock::log_server::use_default_spool_rules: false
simp::rsyslog::stock::log_server::use_default_boot_rules: false

    EOS
  }
  let(:log_server_disable017_hieradata) {
    <<-EOS
#{log_server_disable01_hieradata}
simp::rsyslog::stock::log_server::use_default_security_relevant_logs: false
    EOS
  }

  # Test simp::rsyslog::stock::log_server
  #
  #
  context 'with is_server = true' do
    it 'should configure the server without erros' do
      servers.each do |server|
        set_hieradata_on(server, log_server_hieradata)
        apply_manifest_on(server, log_server_manifest, :catch_failures => true)
      end
    end
    it 'should configure the servers idempotently' do
      servers.each do |server|
        apply_manifest_on(server, log_server_manifest, :catch_changes => true)
      end
    end

    # Log Server Test1: Ensure syslog messages are processed by their
    # intended rule(s), and that there are no re-processed messages (duplicates).
    #
    # Log_servers uses a 3 tier log-local rule hierarchy:
    #   0/1 - facility specific logs
    #   7   - secure.log (security relevant logs)
    #   9   - messages.log
    #
    # Each takes precedence over the next.  For instance, if a
    # 7 rule encompasses a 0/1 rule, the 0/1 rule should process the log message
    # first, then stop processing such that the 7 or 9 rule will not process it.
    #
    # This testing scheme iterates over every 0/1 rule in log_server.pp, and
    # ensures it is not re-processed by 7/9 rules.  7 rules encompassed by 9 rules
    # are tested as well.
    #
    #
    it 'testing default log_server rules' do
      servers.each do |server|
        # 0/1 rules
        # 
        on server, "logger -t sudosh LOGGERSUDOSH"
        on server, "logger -p local0.warn -t httpd LOGGERHTTPDNOERR"
        on server, "logger -p local0.err -t httpd LOGGERHTTPDERR"
        on server, "logger -t dhcpd LOGGERDHCP"
        on server, "logger -p local0.err -t puppet-agent LOGGERPUPPETAGENTERR"
        on server, "logger -p local0.warn -t puppet-agent LOGGERPUPPETAGENTNOERR"
        on server, "logger -p local0.err -t puppet-master LOGGERPUPPETMASTERERR"
        on server, "logger -p local0.warn -t puppet-master LOGGERPUPPETMASTERNOERR"
        # NOTE: on server, "logger -t audispd LOGGERAUDISPD * does not work!"
        on server, "logger -t tag_audit_log LOGGERTAGAUDITLOG"
        on server, "logger -t slapd_audit LOGGERSLAPDAUDIT"
        # NOTE: on server, "IPT does not work!" see logger man page for
        # potential kern issues
        on server, "logger -p mail.warn -t mail LOGGERMAIL"
        on server, "logger -p cron.warn -t cron LOGGERCRON"
        # TODO: test console output for emerge
        on server, "logger -p cron.emerg -t cron LOGGEREMERG"
        on server, "logger -p news.crit -t news LOGGERNEWS"
        on server, "logger -p uucp.warn -t uucp LOGGERUUCP"
        on server, "logger -p local7.warn -t boot LOGGERBOOT"
        # 7 rules
        #
        on server, "logger -t yum LOGGERYUM"
        on server, "logger -p authpriv.warn -t auth LOGGERAUTHPRIV"
        on server, "logger -p local5.warn -t local5 LOGGERLOCAL5"
        on server, "logger -p local6.warn -t local6 LOGGERLOCAL6"
        # 9 rules
        #
        on server, "logger -p local0.info -t info LOGGERINFO"

        # This array maps each tag's message, above, to its template file (log file).
        test_array = [
          ["LOGGERSUDOSH", "sudosh.log"],
          ["LOGGERHTTPDNOERR", "httpd.log"],
          ["LOGGERHTTPDERR", "httpd-err.log"],
          ["LOGGERDHCP", "dhcpd.log"],
          ["LOGGERPUPPETAGENTERR", "puppet-agent-err.log"],
          ["LOGGERPUPPETAGENTNOERR", "puppet-agent.log"],
          ["LOGGERPUPPETMASTERERR", "puppet-master-err.log"],
          ["LOGGERPUPPETMASTERNOERR", "puppet-master.log"],
          ["LOGGERTAGAUDITLOG", "audit.log"],
          ["LOGGERSLAPDAUDIT", "slapd_audit.log"],
          ["LOGGERMAIL", "maillog.log"],
          ["LOGGERCRON", "cron.log"],
          ["LOGGEREMERG", "cron.log"],
          ["LOGGERNEWS", "spooler.log"],
          ["LOGGERUUCP", "spooler.log"],
          ["LOGGERBOOT", "boot.log"],
          ["LOGGERYUM", "secure.log"],
          ["LOGGERAUTHPRIV", "secure.log"],
          ["LOGGERLOCAL5", "secure.log"],
          ["LOGGERLOCAL6", "secure.log"],
          ["LOGGERINFO", "messages.log"]]

        result_dir = "/var/log/hosts/#{fact_on(server,'fqdn')}"

        # Ensure each message ended up in the intended log.
        test_array.each do |message|
          result = on server, "grep -Rl #{message[0]} #{result_dir}"
          expect(result.stdout.strip).to eq("#{result_dir}/#{message[1]}")
        end
      end
    end

    # Log Server Test2: Disable all 0/1 stop rules and test 7/9 rules.
    #
    #
    it 'should disable 0/1 rules' do
      servers.each do |server|
        set_hieradata_on(server, log_server_disable01_hieradata)
        apply_manifest_on(server, log_server_manifest, :catch_failures => true)
      end
    end
    it 'testing log_server with 0/1 stop rules disabled' do
      servers.each do |server|
        on server, "logger -t sudosh LOGGERSUDOSHSECURE"
        on server, "logger -t yum LOGGERYUMSECURE"
        on server, "logger -p cron.warn -t cron LOGGERCRONWARNSECURE"
        on server, "logger -p authpriv.warn -t auth LOGGERAUTHPRIVSECURE"
        on server, "logger -p local5.warn -t local5 LOGGERLOCAL5SECURE"
        on server, "logger -p local6.warn -t local6 LOGGERLOCAL6SECURE"
        on server, "logger -p local7.warn -t boot BOOTSECURE"
        on server, "logger -p cron.emerg -t cron LOGGEREMERGSECURE"
        # NOTE: on server, "IPT does not work!" see logger man page for
        # potential kern issues

        test_array = ["LOGGERSUDOSHSECURE","LOGGERYUMSECURE",
                      "LOGGERCRONWARNSECURE", "LOGGERAUTHPRIVSECURE",
                      "LOGGERLOCAL5SECURE", "LOGGERLOCAL6SECURE",
                      "BOOTSECURE", "LOGGEREMERGSECURE"]
        result_dir = "/var/log/hosts/#{fact_on(server,'fqdn')}"

        test_array.each do |message|
          result = on server, "grep -Rl #{message} #{result_dir}"
          expect(result.stdout.strip).to eq("#{result_dir}/secure.log")
        end
      end
    end

    # Log Server Test3: Disable all 0/1/7 stop rules and test 9 rules.
    #
    #
    it 'should disable 0/1/7 rules' do
      servers.each do |server|
        set_hieradata_on(server, log_server_disable017_hieradata)
        apply_manifest_on(server, log_server_manifest, :catch_failures => true)
      end
    end
    it 'testing log_server with 0/1/7 stop rules disabled' do
      servers.each do |server|
        on server, "logger -p local0.info -t local0 LOGGERLOCAL0MESSAGES"
        on server, "logger -p mail.warn -t mail LOGGERMAILNONEMESSAGES"
        on server, "logger -p authpriv.warn -t authpriv LOGGERAUTHPRIVNONEMESSAGES"
        on server, "logger -p cron.warn -t cron LOGGERCRONNONEMESSAGES"
        on server, "logger -p local6.warn -t local6 LOGGERLOCAL6NONEMESSAGES"
        on server, "logger -p local5.warn -t local5 LOGGERLOCAL5NONEMESSAGES"

        test_array = ["LOGGERMAILNONEMESSAGES", "LOGGERAUTHPRIVNONEMESSAGES",
                      "LOGGERCRONNONEMESSAGES", "LOGGERLOCAL6NONEMESSAGES",
                      "LOGGERLOCAL5NONEMESSAGES"]
        result_dir = "/var/log/hosts/#{fact_on(server,'fqdn')}"

        # *.info should be logged
        result = on server, "grep -Rl LOGGERLOCAL0MESSAGES #{result_dir}"
        expect(result.stdout.strip).to eq("#{result_dir}/messages.log")

        # None of the messages should be logged!
        test_array.each do |message|
          on server, "grep -Rl #{message} #{result_dir}", :acceptable_exit_codes => [1]
        end
      end
    end
  end
end
