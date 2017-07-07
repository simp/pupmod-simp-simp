[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-simp.svg)](https://travis-ci.org/simp/pupmod-simp-dummy) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)

#### Table of Contents

1. [Overview](#overview)
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

## This is a SIMP module
This module is a component of the [System Integrity Management Platform](https://simp-project.com)

If you find any issues, please submit them via [JIRA](https://simp-project.atlassian.net/).

Please read our [Contribution Guide](https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP) and visit our [developer wiki](https://simp-project.atlassian.net/wiki/display/SD/SIMP+Development+Home).

This module should be used within the SIMP ecosystem and will be of limited
independent use

## Module Description

This module provides a convenient entry point for setting up systems to meet
the goals of the SIMP Project.

It is effectively a highly malleable Puppet profile that provides mechanisms
for direct overall system modification and management.

## Setup

### What simp affects

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

## Usage

### Basic Usage

It is recommended that you start with one of the SIMP scenarios described below.

These may be set via the ``simp::scenario`` parameter via Hiera.

You may want to tweak individual module settings and should reference the
[module documentation](https://github.com/simp/pupmod-simp-simp/docs/index.html)
for full details.

#### SIMP Scenarios

The SIMP module has the following scenarios defined for getting started with
different configurations easily:

**NOTE**

| SIMP scenarios always target the Puppet **client** systems. The SIMP server
| is always kept in the safest mode by default but can be overridden explicitly
| in Hiera if desired.

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


# Limitations

SIMP Puppet modules are generally intended to be used on a Red Hat Enterprise
Linux-compatible distribution such as EL6 and EL7.

## Development

Please see the [SIMP Contribution Guidelines](https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP).


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
