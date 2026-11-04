[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/simp.svg)](https://forge.puppetlabs.com/simp/simp)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/simp.svg)](https://forge.puppetlabs.com/simp/simp)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-simp.svg)](https://travis-ci.org/simp/pupmod-simp-simp)

#### Table of Contents

1. [Overview](#overview)
    * [Breaking changes in 11.0.0](#breaking-changes-in-1100)
    * [Breaking changes in 10.0.0](#breaking-changes-in-1000)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with simp](#setup)
    * [What simp affects](#what-simp-affects)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Basic Usage](#basic-usage)
    * [SIMP Scenarios](#simp-scenarios)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
      * [Acceptance Tests - Beaker env variables](#acceptance-tests)

## Overview

This module is the overarching profile of SIMP managed systems. It should be
the entry point for all supported SIMP configurations.

## Breaking changes in 11.0.0

In 11.0.0 the blast radius of `simp::sysctl` was reduced: a bare
`include simp::sysctl` now manages **nothing**. Before 11.0.0 it set about 60
kernel parameters in `/etc/sysctl.conf` and the running kernel to hard-coded
values (including performance tuning such as `net.core.somaxconn` and
`net.ipv4.tcp_{r,w}mem`, which overrode `tuned` and vendor tuning), disabled
IPv6 when `simp::sysctl::ipv6` was unset, and added a PAM limits rule that
prevents core dumps when `simp_options::pam` was `true`. Everything is now
opt-in:

* Every sysctl parameter (`simp::sysctl::<key with . replaced by __>`) defaults
  to `undef`, which leaves the key alone. A value sets the key in
  `/etc/sysctl.conf` and the running kernel. `'absent'` removes the key from
  `/etc/sysctl.conf`; the running kernel value is **not** reset and only
  reverts at the next reboot
* `ipv6` defaults to `undef` (leave `net.ipv6.conf.all.disable_ipv6` alone);
  `false` disables IPv6, `true` enables it, `'absent'` removes the key
* `core_dumps` defaults to `undef`. `true` manages `core_dump_dir`; `false`
  adds the `prevent_core` PAM limits rule when `pam` (`simp_options::pam`) is
  `true`. Where `pam::limits` manages `/etc/security/limits.conf` (it builds
  the whole file from the rules in the catalog), leaving `core_dumps` unset
  **removes** a `prevent_core` line written by an earlier run
* `unmanaged_sysctls` is deprecated: leave the parameter unset instead (`~` in
  Hiera leaves a key unmanaged even when a compliance profile sets it). It
  still works but logs a deprecation warning
* `kernel__exec_shield` is deprecated; it never had an effect

Settings are still written to `/etc/sysctl.conf`, which `systemd-sysctl`
applies as `/etc/sysctl.d/99-sysctl.conf`. A value set here therefore overrides
`/usr/lib/sysctl.d/` and most `/etc/sysctl.d/` drop-ins; a drop-in that sorts
after `99-sysctl.conf` still wins.

The `simp`, `simp_lite`, and `one_shot` scenarios and the `simp::server` class
list still include the class. Until a site opts in with one of the paths below,
on those nodes:

* the class stops enforcing its settings. Values already in `/etc/sysctl.conf`
  remain and are applied at boot; drift is no longer corrected
* the `prevent_core` line is **removed** from `/etc/security/limits.conf`,
  because these scenarios manage that file with `pam::limits`
  (`simp::pam_limits::max_logins`), so core dumps are no longer blocked

* **Path 1 -- enforce the `simp:defaults` compliance profile** (the same
  single Hiera key described for 10.0.0 below). It restores every pre-11.0.0
  value, plus `ipv6: false` and `core_dumps: false`. Override individual keys
  in your own Hiera, which always wins over the profile:

  ```yaml
  compliance_engine::enforcement:
    - simp:defaults
  simp::sysctl::net__core__somaxconn: 4096  # a different value
  simp::sysctl::kernel__panic: ~            # leave it alone
  simp::sysctl::kernel__sysrq: absent       # remove it from /etc/sysctl.conf
  ```

* **Path 2 -- set the parameters yourself** in Hiera, e.g.
  `simp::sysctl::net__ipv4__tcp_syncookies: 1`. The pre-11.0.0 values are
  listed in `SIMP/compliance_profiles/checks.yaml`.

## Breaking changes in 10.0.0

In 10.0.0 the blast radius of `simp::kmod_blacklist` was reduced: a bare
`include simp::kmod_blacklist` now manages **nothing**. It no longer writes the
SCAP Security Guide blacklist to `/etc/modprobe.d` and no longer manages the
`kernel.modules_disabled` sysctl (which, on a locked system, *unlocked* module
loading and requested a reboot). Everything is opt-in:

* `modules` (new) is a Hash of module name => `kmod::blacklist` parameters and
  is the way to blacklist modules. It is empty by default; the 17-module SCAP
  Security Guide list the class used to ship with has moved to the
  `simp:defaults` compliance profile. `modules` is deep-merged across Hiera, so
  a site can add entries, or set `ensure: absent` on one, on top of a
  profile-supplied list without restating it
* Disabled modules are now written to the SIMP drop-in file with
  `kmod::install` entries instead of a whole-file template, so entries are
  managed individually and removed with `ensure: absent`
* `blacklist` and `custom_blacklist` are deprecated in favor of `modules`.
  They still work (their entries are folded into `modules` with default
  options, on top of whatever `modules` already holds) but log a deprecation
  warning
* `enable_defaults` is deprecated and no longer needed; the contents of
  `modules` are the opt-in. Setting it logs a deprecation warning (it does not
  fail the catalog). `false` still means "do not add the deprecated
  `blacklist`"; it has no effect on `modules`
* `lock_modules` (now `Optional[Boolean]`, default `undef`) manages module
  locking: `true` locks, `false` ensures unlocked, `undef` leaves it alone

The `simp`, `simp_lite`, and `one_shot` scenarios and the `simp::server` class
list still include the class; sites using them must opt in with one of the
paths below to keep enforcing the default blacklist.

If you relied on the pre-10.0.0 behavior, there are two ways to restore it.
The `simp:defaults` profile is the recommended path; it is the same profile
name and pattern used across all of the SIMP module rewrites.

* **Path 1 -- enforce the `simp:defaults` compliance profile.** Set a single
  Hiera key:

  ```yaml
  compliance_engine::enforcement:
    - simp:defaults
  ```

  This requires the [Sicura Compliance Engine][compliance_engine] Hiera backend
  (it is **not** a hard dependency of this module -- `metadata.json` is
  unchanged). The profile, shipped in `SIMP/compliance_profiles/`, is a drop-in
  restoration of the *old* behavior: it sets `modules` to the SCAP Security
  Guide list (shown in full under Path 2) and `lock_modules: false`, so the
  default blacklist is enforced and module locking is managed (unlocked)
  exactly as before. It is opinionated for SIMP sites. Sites that want "old
  behavior but safer" can enable the profile and override the individual
  `simp::kmod_blacklist::*` parameters they care about in their own Hiera,
  which always wins over the profile. For example, to keep the SCAP list but
  allow `usb-storage`:

  ```yaml
  simp::kmod_blacklist::modules:
    usb-storage:
      ensure: absent
  ```

  Two pre-10.0.0 configurations do **not** carry over to Path 1 unchanged,
  because the profile supplies the SCAP list through `modules` and the
  deprecated parameters only add to it:

  * `enable_defaults: false` used to mean "no default list at all". With the
    profile enforced it no longer removes the SCAP list.
  * An explicit `blacklist: [a, b]` used to *replace* the default list. Folded
    into `modules` it is now *additive* to the profile list.

  Sites that relied on either should layer `ensure: absent` entries over the
  profile list as shown above, or use Path 2 (and drop the deprecated
  parameters).

* **Path 2 -- set the parameters yourself.** In Hiera:

  ```yaml
  simp::kmod_blacklist::modules:
    bluetooth: {}
    cramfs: {}
    dccp: {}
    dccp_ipv4: {}
    dccp_ipv6: {}
    freevxfs: {}
    hfs: {}
    hfsplus: {}
    ieee1394: {}
    jffs2: {}
    net-pf-31: {}
    rds: {}
    sctp: {}
    squashfs: {}
    tipc: {}
    udf: {}
    usb-storage: {}
  simp::kmod_blacklist::lock_modules: false
  ```

  Best when you want explicit, granular control of exactly what the class
  manages.

[compliance_engine]: https://github.com/simp/rubygem-simp-compliance_engine

## This is a SIMP module
This module is a component of the [System Integrity Management Platform](https://simp-project.com)

If you find any issues, please submit them via [JIRA](https://simp-project.atlassian.net/).

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

This module should be used within the SIMP ecosystem and will be of limited
independent use

## Module Description

This module provides a convenient entry point for setting up systems to meet
the goals of the SIMP Project.

It is effectively a highly malleable Puppet profile that provides mechanisms
for direct overall system modification and management.

## Setup

### What SIMP affects

The ``simp`` module is meant to be the central controller of all node
configurations. The suggested usage is to place the following in your
environment's ``site.pp``:

```ruby
include 'simp_options'
include 'simp'
```

*NOTE:* If using Puppet Enterprise, you can add the ``simp_options`` and
``simp`` classes to nodes via the classification interface. Do be sure to
include ``simp_options`` *before* ``simp`` so that the ``simp`` module has
appropriate access to the parameters in ``simp_options``.

## Reference

See the [REFERENCE.md][reference_md] for a comprehensive overview of the module
components.

## Usage

### Basic Usage

It is recommended that you start with one of the SIMP scenarios described below.

These may be set via the ``simp::scenario`` parameter via Hiera.

| **NOTE** |
| --- |
| <ul><li>`simp::scenario` always affects SIMP **client** systems, no matter how it was set.</li><li>However: SIMP **servers** will default to the `simp` scenario unless `simp:scenario` is set _in Hiera_.</li></ul> |


You may want to tweak individual module settings and should reference the
[module documentation][reference_md] for full details.

[reference_md]: https://github.com/simp/pupmod-simp-simp/blob/master/REFERENCE.md

#### SIMP Scenarios

The SIMP module has the following scenarios defined for getting started with
different configurations easily:

* ``simp``
  * The default scenario. Enables all modules to support the default SIMP
    infrastructure configured around security best practices and compatibility
    with supported security policies as defined in the
    ``compliance_markup`` module.

* ``simp_lite``
  * The ``simp`` profile with some of the more aggressive security support
    modules disabled. These include, but are not limited to, ``iptables``,
    ``fips``, and ``svckill``.

* ``standalone``
  * Applies all of the settings in the ``simp`` profile and, after a successful
    run, either disables ``puppet`` from running again or removes it from the
    system completely. Has options to ensure that there is a way to get back
    into the system afterwards.

* ``poss``
  * The Puppet Open Source Software (POSS) configuration simply attaches your
    node to the Puppet server and performs **no additional configuration**.  This
    can be used as a starting point for building your own configuration without
    needing to worry about how to configure your Puppet agents.

* ``remote_access``
  * Adds the common remote access capabilities of SIMP to the system on top of
    the ``poss`` scenario.

* ``none``
  * Does nothing at all. All configuration is in your control.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

### Unit tests

Unit tests, written in ``rspec-puppet`` can be run by calling:

```shell
bundle exec rake spec
```

### Acceptance tests

To run the system tests, you need [Vagrant](https://www.vagrantup.com/) installed. Then, run:

```shell
bundle exec rake beaker:suites
```

Some environment variables may be useful:

```shell
BEAKER_debug=true
BEAKER_provision=no
BEAKER_destroy=no
BEAKER_use_fixtures_dir_for_modules=yes
```

* `BEAKER_debug`: show the commands being run on the STU and their output.
* `BEAKER_destroy=no`: prevent the machine destruction after the tests finish so you can inspect the state.
* `BEAKER_provision=no`: prevent the machine from being recreated. This can save a lot of time while you're writing the tests.
* `BEAKER_use_fixtures_dir_for_modules=yes`: cause all module dependencies to be loaded from the `spec/fixtures/modules` directory, based on the contents of `.fixtures.yml`.  The contents of this directory are usually populated by `bundle exec rake spec_prep`.  This can be used to run acceptance tests to run on isolated networks.
