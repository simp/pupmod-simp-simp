# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-simp` is the **top-level meta/profile module** of the SIMP (Secure
Infrastructure Management Platform) stack. Unlike a typical SIMP module, it does
not manage one service — it **orchestrates the entire SIMP system**. `include
'simp'` is the single entry point that classifies a node into a coherent,
security-hardened configuration by selecting and including a curated list of
classes drawn from across the whole SIMP module ecosystem.

The orchestration is driven by a **scenario** abstraction. The `simp` class
looks up a `scenario` name, resolves it against a `scenario_map` (a Hash from
module data mapping each scenario to its class list), and `include`s the
resulting classes (`manifests/init.pp`). This is why the module depends
on essentially the entire SIMP stack: it is the thing that wires those modules
together into a working system.

The module is deliberately declarative about *what* a SIMP system is: the
scenario classes (`simp::scenario::base`, `simp::scenario::poss`) encode the
supported configurations, and a large set of `simp::*` helper classes implement
the individual pieces (base packages, mountpoints, sysctl, sudoers, PAM limits,
the SIMP server role, one-shot bootstrap, etc.).

### The scenario model

The `simp` class (`manifests/init.pp`) is the public entry class —
consumers `include 'simp'`. Its behaviour is governed by two data-driven
parameters:

- **`$scenario`** (`String`, default `'simp'`, `init.pp`) — the SIMP
  scenario to apply.
- **`$scenario_map`** (`Hash`, no default; set from module data,
  `init.pp`) — the internal map from scenario name to class list. Defined in
  `data/common.yaml` (`simp::scenario_map`) with the keys `none`,
  `remote_access`, `poss`, `simp_lite`, and `simp`.

Control flow (`init.pp`):

- If `$scenario` is a key in `$scenario_map`, the class list is computed as
  `simp::knockout(union($scenario_map[$scenario], $classes))` — the scenario's
  classes unioned with the caller-supplied `$classes` array, then filtered
  through the `simp::knockout` function which honours a `--` knockout prefix
  (an entry `--ntpd` removes `ntpd` from the list).
- If the resulting list is empty, it emits a `notify` warning that
  auto-classification is disabled (gated on `$classification_warning`) rather
  than failing.
- Otherwise it `include`s the whole computed class list.
- If `$scenario` is **not** a key in the map, the compile `fail`s with
  `ERROR - Invalid scenario '<scenario>' for the given scenario map.`

Two scenario classes are the orchestration entry points:

- **`simp::scenario::base` (`manifests/scenario/base.pp`)** — "what a native
  SIMP system should be." An `assert_private()` class that `inherits simp` and
  conditionally includes the pieces of a hardened baseline based on the boolean
  seams inherited from `simp`: `simp::sssd::client` (when `$sssd and
  $stock_sssd`), `simp::sudoers`, `simp::ctrl_alt_del`, `simp::root_user`,
  `simp::pam_limits::max_logins` (when `$restrict_max_logins and $pam`),
  `postfix`/`postfix::server` (mail), `simp::rc_local`, a `host` entry for the
  Puppet server (from `$server_facts`), optional `ssh::global_known_hosts`, and
  an `rsync` stunnel connection to the Puppet server on port 8730
  (`scenario/base.pp`).
- **`simp::scenario::poss` (`manifests/scenario/poss.pp`)** — the "Puppet Open
  Source Software" scenario. An `assert_private()` class (`inherits simp`) that
  provides a *minimal* client which merely connects to a SIMP Puppet server. It
  applies **no security hardening** — its only resource is an optional `host`
  entry for the Puppet server. This is the scenario to use for a stock Puppet
  experience (it also works on Puppet Enterprise).

### one_shot: bootstrap-only logic

The `simp::one_shot` subtree is **not** part of the standard SIMP run — it
exists to bootstrap or tear down a stand-alone system that disconnects from the
Puppet server after a successful run.

- **`simp::one_shot` (`manifests/one_shot.pp`)** — asserts the module metadata
  with `Windows` blacklisted (`one_shot.pp`), `contain`s
  `simp::one_shot::user`, defines a late run `stage`
  (`simp_one_shot_finalization`, ordered after `simp_finalize`), and runs
  `simp::one_shot::finalize` in that stage so finalization only happens if all
  prior configuration succeeded.
- **`simp::one_shot::user` (`manifests/one_shot/user.pp`)** —
  `assert_private()`; creates/removes a stand-alone local user with SSH key,
  `pam::access` rule, and a `sudo::user_specification`.
- **`simp::one_shot::finalize` (`manifests/one_shot/finalize.pp`)** —
  `assert_private()`; drops a `simp_one_shot_finalize.sh` script and runs it in
  the background (`&`, `provider => shell`) so it can remove PKI, the puppet
  package, and itself without breaking the in-flight Puppet run.

### Other resource classes

The remaining classes implement individual baseline concerns and are included
via the scenario map / scenario classes rather than directly. Grouped by
subdirectory:

- **top-level `manifests/*.pp`** — `simp::admin` (admin/auditor group access
  and default sudo rules), `simp::base_apps` (common apps such as irqbalance),
  `simp::base_services` (**deprecated**, slated for removal), `simp::ctrl_alt_del`,
  `simp::kmod_blacklist`, `simp::mountpoints`, `simp::netconsole`,
  `simp::nsswitch`, `simp::prelink`, `simp::puppetdb`, `simp::rc_local`,
  `simp::root_user`, `simp::server` (the SIMP server role), `simp::sudoers`,
  `simp::sysctl`, and `simp::version`.
- **`kmod_blacklist/`** — `lock_modules`.
- **`mountpoints/`** — `proc`, `tmp` (secure mount options).
- **`pam_limits/`** — `max_logins` (simultaneous-login restriction).
- **`server/`** — `kickstart`, `kickstart/simp_client_bootstrap`,
  `rsync_shares`, `yum` (server-role provisioning).
- **`sssd/`** — `client` (stock SSSD stack).
- **`sudoers/`** — `aliases` (SIMP site sudoers aliases).
- **`yum/`** — `schedule`, plus a set of `yum/repo/*` repo-definition classes
  (`internet_simp`, `internet_simp_dependencies`, `internet_simp_server`,
  `local_os_updates`, `local_simp`).

There are roughly **39 classes** in total across `manifests/` (18 top-level
`manifests/*.pp` plus ~21 subclasses under the subdirectories above). Summarize
by role rather than enumerating each one when working here.

### Gotchas / non-obvious details

- **This is a meta-module, not a service module.** Almost nothing here manages a
  daemon directly; the module's job is *classification* — pick a scenario, union
  in extra classes, knock out unwanted ones, and `include` the result
  (`init.pp`). Changes to what a "SIMP system" includes usually belong
  in the `scenario_map` in `data/common.yaml`, not in new manifest logic.
- **The scenario is data-driven.** `$scenario_map` and `$classes` both merge
  across the Hiera hierarchy (`data/common.yaml` sets deep/unique merge
  behaviour and defines the `simp::knockout` `--` prefix semantics). An
  invalid scenario name is a hard compile `fail` (`init.pp`).
- **`simplib::module_metadata::assert` is intentionally NOT called in
  `simp::init`** — this is deliberate, to permit non-SIMP OSes to use the `poss`
  scenario (`init.pp`). Contrast `simp::one_shot`, which *does* assert
  (with `Windows` blacklisted, `one_shot.pp`).
- **`poss` provides no security.** It is a bare client-to-server connection;
  do not assume any hardening is applied under the `poss` scenario
  (`scenario/poss.pp`).
- **Bolt-awareness.** The `$facts['puppet_vardir']}/simp` directory and the
  filebucket are skipped under `simplib::in_bolt()` because the vardir would be
  on the Bolt host, not the target (`init.pp`).
- **`simp::base_services` is deprecated** and will be removed in a future
  version (`manifests/base_services.pp`); do not build new logic on it.
- **`enable_data_includes` is deprecated and has no effect** (`init.pp`);
  it is slated for removal in the next major release.
- **one_shot finalization is destructive and asynchronous.** It runs a script in
  the background that can remove PKI and the puppet package
  (`one_shot/finalize.pp`); it is not part of a normal run and should not
  be enabled on managed clients.
- **Windows in the OS matrix is vestigial.** `metadata.json` still carries a
  legacy Windows entry, but the module and its acceptance suite are EL-only in
  practice.

## The `simp_options` / `simplib::lookup` seam

Like every SIMP module, `simp` routes cross-cutting feature toggles through the
`simp_options::*` namespace via `simplib::lookup(..., { 'default_value' => ...
})`, so a site can flip a capability once and have it propagate. There are **15**
distinct `simp_options::*` seams consumed across the manifests:

`simp_options::auditd`, `simp_options::authselect`, `simp_options::clamav`,
`simp_options::fips`, `simp_options::firewall`, `simp_options::ldap`,
`simp_options::ntpd::servers`, `simp_options::package_ensure`,
`simp_options::pam`, `simp_options::puppet::ca`, `simp_options::puppet::ca_port`,
`simp_options::puppet::server`, `simp_options::sssd`, `simp_options::stunnel`,
`simp_options::trusted_nets`.

In `simp::init` specifically, `$rsync_stunnel`, `$pam`, `$ldap`, and `$sssd`
default off the `simp_options::stunnel` / `::pam` / `::ldap` / `::sssd` seams
(`init.pp`). Keep new toggles flowing through
`simplib::lookup('simp_options::*', { 'default_value' => ... })` with an
explicit default rather than assuming `simp_options` is included.

## Dependencies

This is a **meta-module: it depends on essentially the entire SIMP stack.**
`metadata.json` declares **43** dependencies — do not transcribe them all when
editing; treat the dependency list as "the whole SIMP ecosystem." A
representative handful:

- `simp/pupmod` `>= 10.0.0 < 11.0.0`
- `simp/simplib` `>= 4.9.0 < 5.0.0` (provides `simplib::lookup`,
  `simplib::knockout`/`simp::knockout` support, `simplib::in_bolt`,
  `simplib::module_metadata::assert`, `runlevel`, facts)
- `simp/ssh` `>= 6.11.0 < 7.0.0`
- `simp/sssd` `>= 7.0.0 < 8.0.0`
- `simp/stunnel` `>= 7.0.0 < 8.0.0`
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0`

There are **no optional dependencies** — the module makes no
`simplib::assert_optional_dependency` calls.

Runtime requirement (from `metadata.json` `requirements`): `puppet
>= 8.0.0 < 9.0.0`. Note that the `Gemfile` `puppet_version` default is a
separate, looser range (`>= 7 < 9`, see below) — the runtime requirement is the
authoritative `>= 8 < 9`. (SIMP is migrating Puppet → OpenVox; when
`metadata.json` switches `requirements` to `openvox`, update this line to match.)

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10. A legacy Windows entry
(2008 / 2008 R2 / 2012 / 2012 R2 / 2016 / 2019 / 7 / 8.1 / 10) is also present in
`metadata.json` but is **vestigial** — the module and its acceptance suite are
EL-only in practice.

## Repository layout

- `manifests/init.pp` — the public `simp` class; scenario resolution +
  classification (the orchestration core).
- `manifests/scenario/base.pp`, `manifests/scenario/poss.pp` — the two
  orchestration entry points (both `assert_private()`, both `inherits simp`).
- `manifests/one_shot.pp`, `manifests/one_shot/user.pp`,
  `manifests/one_shot/finalize.pp` — bootstrap/teardown for stand-alone hosts
  (not part of a normal run).
- `manifests/*.pp` and the `kmod_blacklist/`, `mountpoints/`, `pam_limits/`,
  `server/`, `sssd/`, `sudoers/`, `yum/` subdirectories — the individual
  baseline classes (~39 classes total).
- `data/common.yaml` — the `scenario_map`, class lists, nsswitch defaults, and
  merge behaviours. **This is where "what a SIMP system includes" lives.**
- `data/os/`, `hiera.yaml` — module data hierarchy (v5): OS name+major → OS name
  → kernel → common.
- `metadata.json` — the 43 dependencies, OS matrix, and Puppet requirement.
- `spec/classes/`, `spec/defines/` — rspec-puppet unit tests.
- `spec/acceptance/suites/` — beaker suites (`default`, `base_apps`); nodesets
  under `spec/acceptance/nodesets/` (**30** files: a `vagrant` set —
  almalinux8/9/10, centos9/10, oel8/9/10, rhel8/9/10, rocky8/9/10, amzn2 — and a
  `docker_*` set).
- `REFERENCE.md` — generated Puppet Strings reference.
- **`assert_private()` callers:** `manifests/one_shot/finalize.pp`,
  `manifests/scenario/base.pp`, `manifests/one_shot/user.pp`,
  `manifests/scenario/poss.pp` — these are internal-only classes reached through
  `simp` / `simp::one_shot`, never included directly.
- **Acceptance runs in CI:** `.github/workflows/pr_tests.yml` has an active
  `acceptance` job (matrix node ∈ {`almalinux8`, `almalinux10`} × suite ∈
  {`default`, `base_apps`}) whose final step runs `bundle exec rake
  beaker:suites[<suite>,<node>]` under `BEAKER_HYPERVISOR=vagrant_libvirt` and
  `VAGRANT_DEFAULT_PROVIDER=libvirt` (Ruby 3.4.9).

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run a beaker acceptance suite (matches CI: suite x node)
bundle exec rake beaker:suites[default,almalinux8]
bundle exec rake beaker:suites[base_apps,almalinux10]
```

`spec/spec_helper.rb` requires `puppetlabs_spec_helper/module_spec_helper`.
Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.24.0`, `simp-beaker-helpers ~> 2.0.0`. Rubocop is pinned
to `~> 1.88.0`. The `Gemfile` installs only the `puppet` gem (no `openvox` gem
yet) and its `puppet_version` default is `>= 7 < 9`; the authoritative runtime
requirement in `metadata.json` is `>= 8 < 9`.

## Conventions

- **Change the scenario map, not the manifest, to change what SIMP includes.**
  The class list for each scenario is data (`data/common.yaml` →
  `simp::scenario_map`); adding a class to the baseline usually means editing
  that data, not `init.pp`.
- **Keep the two public entry points thin.** `simp::init` classifies;
  `simp::scenario::base` / `::poss` orchestrate. New per-concern logic belongs in
  a dedicated `simp::*` class that the scenario includes, guarded by a boolean
  seam.
- **Preserve `assert_private()`** on scenario and one_shot classes — they are
  internal and reached only through `simp` / `simp::one_shot`.
- **Do not add `simplib::module_metadata::assert` to `simp::init`** — its
  absence is intentional so non-SIMP OSes can use `poss` (`init.pp`).
- Continue routing SIMP feature toggles through
  `simplib::lookup('simp_options::*', { 'default_value' => ... })` with an
  explicit default rather than assuming `simp_options` is included.
- Preserve the `@summary` / `@param` puppet-strings docstrings — they drive
  `REFERENCE.md`. Regenerate `REFERENCE.md` after changing docs or parameters.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used across `manifests/`.
