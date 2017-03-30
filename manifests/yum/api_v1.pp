# API v1 abstraction for simp::yum
class simp::yum::api_v1 inherits ::simp::yum {
  assert_private()

  $_simp_repo_enable = $enable_simp_repos ? { true => 1, default => 0 }
  $_os_repo_enable   = $enable_os_repos ?   { true => 1, default => 0 }

  if $enable_auto_updates == true {
    include '::simp::yum::schedule'
  }
  else {
    cron { 'simp_yum_update': ensure => 'absent' }
  }

  if empty($os_gpg_url) {
    $_temp_os_gpg_url = $facts['os']['name'] ? {
      'RedHat' => "https://YUM_SERVER/yum/${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}/RPM-GPG-KEY-redhat-release",
      default  => "https://YUM_SERVER/yum/${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}/RPM-GPG-KEY-${facts['os']['name']}-${facts['os']['release']['major']}"
    }

    $_os_gpg_url = simp_yumrepo_mangle($_temp_os_gpg_url, $servers)
  }
  else {
    $_os_gpg_url = simp_yumrepo_mangle($os_gpg_url, $servers)
  }

  if empty($simp_gpg_url) {
    $_simp_gpg_url = simp_yumrepo_gpgkeys('https://YUM_SERVER/yum/SIMP', $servers)
  }
  else {
    $_simp_gpg_url = simp_yumrepo_mangle($simp_gpg_url, $servers)
  }

  yumrepo { 'os_updates':
    baseurl         => simp_yumrepo_mangle($os_update_url, $servers),
    descr           => "All ${facts['os']['name']} ${facts['os']['release']['major']} ${facts['architecture']} base packages and updates",
    enabled         => $_os_repo_enable,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => join(split($_os_gpg_url,"\n"),"\n   "),
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => 3600,
    tag             => 'firstrun'
  }

  yumrepo { 'simp':
    baseurl         => simp_yumrepo_mangle($simp_update_url, $servers),
    descr           => 'SIMP Packages',
    enabled         => $_simp_repo_enable,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => join(split($_simp_gpg_url,"\n"),"\n   "),
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => 3600,
    tag             => 'firstrun'
  }
}
