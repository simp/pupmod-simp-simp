# simp::merge_scenario_classes()
#
# merge the classes from the selected scenario, plus any additions from the
# the classes parameter, and minus any classes prefixed with `--`.
#
# @private
function simp::merge_scenario_classes(String $scenario = "", Hash[String, Array] $scenario_map = {}, Optional[Array] $classes = undef) {
  $_classes = $classes ? {
    undef   => [],
    default => $classes,
  }
  if ($scenario_map == {}) {
    $selected_classes = $_classes
  } elsif $scenario_map.has_key($scenario) {
    $selected_classes = $scenario_map[$scenario] + $_classes
  } else {
    fail("ERROR - Invalid scenario '${scenario}' for the given scenario map.")
  }

  simp::knockout($selected_classes)
}
