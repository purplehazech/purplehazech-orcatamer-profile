# # Class: profile::logstash
#
#
class profile::logstash {
  exec { 'layman-add-chaos-overlay':
    command => '/usr/bin/layman-add chaos git git://github.com/travisghansen/chaos.git',
    creates => '/var/lib/layman/chaos',
  } ~>
  exec { 'eix-update-for-chaos-overlay':
    command     => '/usr/bin/eix-update',
    refreshonly => true,
  } ->
  package_keywords { [
    'dev-python/urllib3',
    'dev-python/pyes',
  ]:
    ensure   => present,
    keywords => [
      '~amd64',
    ],
  } ->
  package { 'sys-apps/logstash':
    ensure => installed,
  } ->
  file { '/etc/logstash/conf.d/syslog.conf':
    ensure => file,
    source => '/vagrant/manifests/profile/templates/logstash/syslog.conf.erb',
    notify => Service['logstash'],
  }
  augeas { 'logstash-confd':
    context => '/files/etc/conf.d/logstash',
    lens    => 'Shellvars.lns',
    incl    => '/etc/conf.d/logstash',
    changes => [
      'set WEB_START true',
    ]
  } ~>
  service { 'logstash':
    ensure => running,
  } ~>
  exec { 'restart-syslog-ng-after-logstash':
    command     => '/etc/init.d/syslog-ng restart',
    refreshonly => true,
  }
}
