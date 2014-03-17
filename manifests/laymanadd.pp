# # Class: profile::laymanadd
#
#
class profile::laymanadd {

  layman {
    # overlay containing layman-add tool
    'betagarden':
      ensure => present,
  } ~>
  exec { 'sync-eix-for-betagarden':
    command     => '/usr/bin/eix-update',
    refreshonly => true,
  } ->
  package_keywords { 'app-portage/layman-add':
    ensure   => 'present',
    keywords => '~amd64',
  }
  package { 'app-portage/layman-add':
    ensure  => present,
    require => Class['sudo']
  }

}
