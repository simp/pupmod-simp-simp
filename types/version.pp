# Version of the form 'X', 'X.Y', 'X.Y.Z' or 'X.Y.Z-N'
type Simp::Version = Pattern['^[0-9]+(((\.[0-9]+){1,2})|((\.[0-9]+){2}\-[0-9]+))?$']
