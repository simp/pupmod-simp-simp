# Include the correct cloud config based on the simp_cloud fact
#
class simp::cloud {
  case $simp_cloud {
    'amazon':  { contain 'bootstrap::cloud::amazon' }
    'vagrant': { contain 'bootstrap::cloud::vagrant' }
    # 'azure':   { contain 'bootstrap::cloud::azure' }
    # 'gce':     { contain 'bootstrap::cloud::gce' }
    # 'xen':     { contain 'bootstrap::cloud::xen' }
    # default:   { contain "bootstrap::cloud::${simp_cloud}" }
    default:   { notice("${simp_cloud} is not supported") }
  }
}
