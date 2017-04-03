type Simp::HostOrURL = Variant[
  Simplib::Host,
  Simplib::Host::Port,
  Simplib::Hostname,
  Simplib::Hostname::Port,
  Simplib::IP::V4,
  Simplib::IP::V4::Port,
  Simplib::IP::V6,
  Simplib::IP::V6::Port,
  Stdlib::HTTPSUrl,
  Stdlib::HTTPUrl
]
