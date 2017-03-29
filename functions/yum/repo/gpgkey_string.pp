function simp::yum::repo::gpgkey_string(
  Array[Simp::Hostorurl] $servers,
  Array[String]          $simp_gpgkeys,
  String                 $simp_baseurl_path,
  Simp::Urls             $extra_gpgkey_urls = [],
) >> String {
  $_standard_gpgkey_urls = $servers.filter |$_server| {
    $_server !~ Variant[Stdlib::HTTPSUrl,Stdlib::HTTPUrl]
  }.map |$_server| {
    $simp_gpgkeys.map |$_gpgkey| { "https://${_server}/yum/${simp_baseurl_path}/${_gpgkey}" }
  }

  # smoosh everything into a `yumrepo`-compatible String
  join(concat($_standard_gpgkey_urls, $extra_gpgkey_urls), "\n    ")
}
