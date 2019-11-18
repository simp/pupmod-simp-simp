# Valid package resource 'ensure' settings
type Simp::PackageEnsure = Enum[
  'latest',
  'absent',
  'present',
  'installed'
]
