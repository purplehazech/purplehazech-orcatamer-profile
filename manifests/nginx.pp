# # Class profile::nginx
#
#
class profile::nginx {

  package { 'www-servers/nginx':
    ensure => present,
  } ->
  file { '/etc/nginx/conf.d':
    ensure => directory
  } ->
  class { '::nginx': } ->
  exec { 'nginx-add-conf.d':
    command => '/bin/sed --in-place -e "s@include /etc/nginx/mime.types;@include /etc/nginx/mime.types;\n\tinclude /etc/nginx/conf.d/*.conf;@" /etc/nginx/nginx.conf',
    unless  => '/bin/grep "include /etc/nginx/conf.d/\*.conf;" /etc/nginx/nginx.conf',
  } ~>
  exec { 'restart-nginx-after-conf':
    command     => '/etc/init.d/nginx restart',
    refreshonly => true
  }

}
