# # Class: profile::pumpio
#
# Install a pump.io server.
#
# This module is very incomplete due to the various reasons.
# * pump.io is hard to run on shared infrastructure
# * running pump.io behind a proxy does not seem sensible
#
# I'm leaving this here for now. As pump.io matures I might
# use it again to build a pump.io server.
#
# Here are more things that I want pump.io to do before I
# consider it again.
# * easy way to swap out ``/`` page with some static content
#   of my own liking.
# * way to either run behind a proxy or maybe even act as a
#   proxy so I have a way to replicate the various parts my
#   legacy apache setup has accumulated.
#
class profile::pumpio {
  file { [
    '/srv',
    '/srv/www',
    "/srv/www/${::hostname}",
    "/srv/www/${::hostname}/uploads",
    ]:
      ensure => directory
  } ->
  package { 'pump.io':
    ensure   => present,
    provider => 'npm',
  } ->
  package { 'databank-mongodb':
    ensure   => present,
    provider => 'npm',
  } ->
  file { [
      '/etc/pump.io',
      '/etc/pump.io/ssl'
    ]:
      ensure => directory
  } ->
  openssl::certificate::x509 { 'server':
    country      => 'CH',
    organization => 'purplehaze.ch',
    commonname   => $::fqdn,
    base_dir     => '/etc/pump.io/ssl'
  } ->
  file { '/etc/pump.io.json':
    content => template('profile/pumpio/pump.io.json.erb')
  }
}
