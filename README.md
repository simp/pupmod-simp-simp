[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/simp.svg)](https://forge.puppetlabs.com/simp/simp)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/simp.svg)](https://forge.puppetlabs.com/simp/simp)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-simp.svg)](https://travis-ci.org/simp/pupmod-simp-simp)

#### Table of Contents

1. [Overview](#overview)
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

## Breaking changes in 10.0.0

In 10.0.0 the blast radius of `simp::kmod_blacklist` was reduced: a bare
`include simp::kmod_blacklist` now manages **nothing**. It no longer writes the
SCAP Security Guide blacklist to `/etc/modprobe.d` and no longer manages the
`kernel.modules_disabled` sysctl (which, on a locked system, *unlocked* module
loading and requested a reboot). Everything is opt-in:

* `blacklist` is now empty by default. The 17-module SCAP Security Guide list
  it used to ship with has moved to the `simp:defaults` compliance profile
* `enable_defaults` is deprecated and no longer needed; the contents of
  `blacklist` are the opt-in. Setting it logs a deprecation warning (it does
  not fail the catalog). `false` is still honored and ignores `blacklist`, so
  a site that enforces the profile but sets `enable_defaults: false` gets only
  its `custom_blacklist`, as before. Remove the key, or replace it with
  `simp::kmod_blacklist::blacklist: []`
* `custom_blacklist` still blacklists additional modules on top of `blacklist`,
  so a site can add modules without overriding a profile-supplied list
* `purge_blacklist` (new) removes specific entries a previous configuration
  added; nothing is un-blacklisted automatically any more
* `lock_modules` (now `Optional[Boolean]`, default `undef`) manages module
  locking: `true` locks, `false` ensures unlocked, `undef` leaves it alone

The `simp`, `simp_lite`, and `poss` scenarios still include the class; sites
using a scenario must opt in with one of the paths below to keep enforcing the
default blacklist.

If you relied on the pre-10.0.0 behavior, there are two ways to restore it:

* **Path 1 -- set the parameters yourself.** In Hiera:

  ```yaml
  simp::kmod_blacklist::blacklist:
    - bluetooth
    - cramfs
    - dccp
    - dccp_ipv4
    - dccp_ipv6
    - freevxfs
    - hfs
    - hfsplus
    - ieee1394
    - jffs2
    - net-pf-31
    - rds
    - sctp
    - squashfs
    - tipc
    - udf
    - usb-storage
  simp::kmod_blacklist::lock_modules: false
  ```

  Best when you want explicit, granular control of exactly what the class
  manages.

* **Path 2 -- enforce the `simp:defaults` compliance profile.** Set a single
  Hiera key:

  ```yaml
  compliance_engine::enforcement:
    - simp:defaults
  ```

  This requires the [Sicura Compliance Engine][compliance_engine] Hiera backend
  (it is **not** a hard dependency of this module -- `metadata.json` is
  unchanged). The profile, shipped in `SIMP/compliance_profiles/`, is a drop-in
  restoration of the *old* behavior: it sets `blacklist` to the SCAP Security
  Guide list above and `lock_modules: false`, so the default blacklist is
  enforced and module locking is managed (unlocked) exactly as before. It is
  opinionated for SIMP sites. Sites that want "old behavior but safer" can
  enable the profile and override the individual `simp::kmod_blacklist::*`
  parameters they care about in their own Hiera, which always wins over the
  profile.

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
