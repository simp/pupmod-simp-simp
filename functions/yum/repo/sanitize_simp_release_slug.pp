# Sanitize the release slug in the SIMP repo URLs
#
# @param simp_release_slug
#   The ``slug`` to sanitize
#
# @return String
#
function simp::yum::repo::sanitize_simp_release_slug(
  Variant[String,Undef] $simp_release_slug = undef
) {

  if defined('$simp_release_slug') and !empty($simp_release_slug) {
    $_release_slug = $simp_release_slug
  }
  else {
    $simp_version = simp_version()
    $_simp_maj_version = (split($simp_version,'\.'))[0]

    if $_simp_maj_version in ['6', '5'] {
      $_release_slug = "${_simp_maj_version}_X"
    }
    else {
      fail("SIMP version ${simp_version} does not map to a known yum repository slug")
    }
  }
  err "XXX release_slug [${_release_slug}]"
  $_release_slug
}
