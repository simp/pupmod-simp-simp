# @summary DEPRECATED Configure yum to use the internet public repositories for SIMP dependencies
#
# The packagecloud yum repository that used to be configured by this class is
# no longer maintained. As an interim workaround, this class now uses
# ``simp::yum::repo::internet_simp`` to configure the correct repositories. You
# should switch to using ``simp::yum::repo::internet_simp directly``, as this
# class will be removed in a future release.
#
# @param simp_release_slug
#   The unique release URL "slug" of SIMP for the target release.
#
class simp::yum::repo::internet_simp_dependencies (
  Optional[String] $simp_release_slug = undef
){

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  # TODO remove this class and the function called when the version
  # of this module is bumped to 5.0.0.
  warning('simp::yum::repo::internet_simp_dependencies is deprecated and will be removed in the next major release. Please use simp::yum::repo::internet_simp directly instead.')

  $_release_slug = simp::yum::repo::sanitize_simp_release_slug( $simp_release_slug )
  yumrepo { "simp-project_${_release_slug}_Dependencies": ensure => absent }

  include 'simp::yum::repo::internet_simp'
}
