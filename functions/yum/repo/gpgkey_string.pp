# A function to return a proper set of SIMP YUM repositories for the default
# build. Of limited use outside of an ISO install.
#
# @param servers
#   The list of YUM servers
#
# @param simp_gpgkeys
#   The list of GPG Keys for SIMP
#
# @param simp_baseurl_path
#   The standard path to the yum repos on the servers
#
# @param extra_gpgkey_urls
#   Additional GPG keys that need to be included
#
# @return [String]
function simp::yum::repo::gpgkey_string(
  Array[Simp::HostOrURL] $servers,
  Array[String]          $simp_gpgkeys,
  String                 $simp_baseurl_path,
  Simp::Urls             $extra_gpgkey_urls = [],
) {
  $_standard_gpgkey_urls = $servers.filter |$_server| {
    $_server !~ Variant[Stdlib::HTTPSUrl,Stdlib::HTTPUrl]
  }.map |$_server| {
    $simp_gpgkeys.map |$_gpgkey| { "https://${_server}/yum/${simp_baseurl_path}/${_gpgkey}" }
  }

  # smoosh everything into a `yumrepo`-compatible String
  join(concat($_standard_gpgkey_urls, $extra_gpgkey_urls), "\n    ")
}
