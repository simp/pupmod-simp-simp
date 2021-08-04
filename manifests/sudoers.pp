# @summary Provide useful aliases that many people have wanted to use over
# time.
#
# None of this is mandatory and all can be changed via the different
# parameters.
#
# Each section simply adds the entry to the sudoers file by joining
# the array together appropriately.
#
# @param common_aliases
#   Enable the 'common' aliases from ``simp::suoders::aliases``
#
# @param default_entry
#   The global default entry that should apply to **all** users
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::sudoers (
  Boolean $common_aliases = false,
  Array $default_entry    = [
    '!visiblepw',
    'always_set_home',
    'match_group_by_gid',
    'always_query_group_plugin',
    'listpw=all',
    'requiretty',
    'syslog=authpriv',
    '!root_sudo',
    '!umask',
    'secure_path = /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    'env_reset',
    'env_keep = "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR \
      LS_COLORS MAIL PS1 PS2 QTDIR USERNAME \
      LANG LC_ADDRESS LC_CTYPE LC_COLLATE LC_IDENTIFICATION \
      LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC \
      LC_PAPER LC_TELEPHONE LC_TIME LC_ALL LANGUAGE LINGUAS \
      _XKB_CHARSET XAUTHORITY"'
  ]
) {

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  include 'sudo'

  sudo::default_entry { '00_main':
    content => $default_entry
  }

  if $common_aliases { include 'simp::sudoers::aliases' }
}
