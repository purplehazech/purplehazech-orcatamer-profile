# # Class: profile::pumpio
#
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
  file { '/etc/pump.io.json':
    content => template('profile/pumpio/pump.io.json.erb')
  }
}
