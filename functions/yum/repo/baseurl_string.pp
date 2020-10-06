# @return [String]
function simp::yum::repo::baseurl_string(
  Array[Simp::HostOrURL] $servers,
  String                 $simp_baseurl_path,
) {
  $_server_urls = $servers.map |$_server| {
    if $_server =~ Variant[Stdlib::HTTPSUrl,Stdlib::HTTPUrl] {
      regsubst($_server, '/$', '')
    }
    else {
      "https://${_server}/yum/${simp_baseurl_path}"
    }
  }
  $_server_urls.join("\n    ")
}
