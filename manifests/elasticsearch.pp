# # Class: profile::elasticsearch
#
#
class profile::elasticsearch {
  portage::package { 'app-misc/elasticsearch':
    ensure   => installed,
    keywords => [
      '~amd64'
    ],
  } ->
  file { '/etc/elasticsearch/elasticsearch.in.sh':
    ensure     => file,
    source     => '/etc/elasticsearch/elasticsearch.in.sh.sample',
  } ->
  file { '/etc/elasticsearch/elasticsearch.yml':
    ensure     => file,
    source     => '/etc/elasticsearch/elasticsearch.yml.sample',
  } ->
  file { '/etc/elasticsearch/logging.yml':
    ensure     => file,
    source     => '/etc/elasticsearch/logging.yml.sample',
  } ->
  service { 'elasticsearch':
    ensure => running,
    enable => true
  }
}
