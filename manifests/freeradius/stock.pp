# == Class: simp::freeradius::stock
#
# Provide a default configuration of FreeRadius that matches the one from Red
# Hat.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::freeradius::stock {
  include 'freeradius'
  include 'freeradius::users'
  include 'freeradius::conf::client'

  # Must set client_nets variable in hiera for this to work properly
  include 'freeradius::conf'

  freeradius::conf::client::add { 'default':
    ipaddr => '127.0.0.1'
  }

  include 'freeradius::conf::instantiate'

  freeradius::conf::listen::add { 'default_auth':
    listen_type => 'auth'
  }

  include 'freeradius::conf::log'
  include 'freeradius::conf::modules'
  include 'freeradius::conf::security'
  include 'freeradius::conf::thread_pool'

  # These set up the normal DEFAULT entries.
  freeradius::users::add { 'default_ppp':
    is_default => true,
    content    => '
      Framed-Protocol == PPP
      Framed-Protocol = PPP,
      Framed-Compression = Van-Jacobson-TCP-IP'
  }
  freeradius::users::add { 'default_cslip':
    is_default => true,
    content    => '
      Hint == "CSLIP"
      Framed-Protocol = SLIP,
      Framed-Compression = Van-Jacobson-TCP-IP'
  }
  freeradius::users::add { 'default_slip':
    is_default => true,
    content    => '
      Hint == "SLIP"
      Framed-Protocol = SLIP'
  }
}
