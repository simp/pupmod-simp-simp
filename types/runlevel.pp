# Valid system runlevel settings
type Simp::Runlevel = Variant[
  Enum['rescue','multi-user','graphical'],
  Integer[1,5]
]
