# # Class: profile::puppet::master
#
# Contains the run book for installing a complete puppetmaster setup on
# a current gentoo node. Since this run book uses some highly experimental
# tooling it will not run on any platform other than gentoo anytime soon.
#
# The largest problems with this run book are as follows.
# * puppetdb is installed from binaries using leiningen
# * puppetboard is installed using pip
# * it should use postgresql as intended by puppetdb
#
# The rest of the run book is ready to be installed from binaries, so
# at least its got that going.
#
class profile::puppet::master {

  $optiz0r_overlay = 'https://github.com/optiz0r/gentoo-overlay.git'
  $rabe_overlay = 'https://github.com/purplehazech/rabe-portage-overlay.git'

  # puppetdb
  exec {
    # overlay with leiningen
    'layman-add-optiz0r-overlay':
      command => "/usr/bin/layman-add optiz0r git ${optiz0r_overlay}",
      creates => '/var/lib/layman/optiz0r';
    # overlay with more current puppetdb than optiz0r
    'layman-add-rabe-overlay':
      command => "/usr/bin/layman-add rabe git ${rabe_overlay}",
      creates => '/var/lib/layman/rabe',
  } ~>
  exec { 'sync-eix-for-puppetdb':
    command     => '/usr/bin/eix-update',
    refreshonly => true,
  } ->
  package_keywords { [
    'app-admin/puppetdb',
    'dev-lang/leiningen',
  ]:
    ensure   => present,
    keywords => '~amd64',
  } ->
  package { [
    'dev-lang/clojure',
    'app-admin/puppetdb'
  ]:
    ensure => present,
  } ->
  file { [
    '/var/run/puppetdb',
    '/var/lib/puppetdb/state',
    '/var/lib/puppetdb/db',
    '/var/lib/puppetdb/config',
    '/var/lib/puppetdb/mq',
  ]:
    ensure => directory,
    owner  => 'puppetdb',
  } ->
  file { '/etc/puppetdb/conf.d':
    ensure => directory,
    mode   => '0755',
  } ->
  file { '/etc/puppetdb/log4j.properties':
    ensure => file,
    mode   => '0644',
  } ->
  service { 'puppetdb':
    ensure => running,
    enable => true
  }

  # puppetboard
  $www_root        = '/var/www/puppet.vagrant.local/'
  $settings_file   = '/var/www/puppet.vagrant.local/settings.py'
  $wsgi_script     = '/var/www/puppet.vagrant.local/wsgi.py'
  $puppetboard_dir = '/usr/lib64/python2.7/site-packages/puppetboard/'
  $settings_tpl    = "${puppetboard_dir}/default_settings.py"
  package { 'dev-python/pip':
    ensure  => present,
    require => Service['puppetdb']
  } ->
  package { 'www-servers/nginx':
    ensure => present,
  } ->
  portage::package { 'www-servers/uwsgi':
    ensure   => present,
    use      => [
      'python',
    ],
    keywords => [
      '~amd64',
    ],
  } ->
  exec { 'pip-install-puppetboard':
    command => '/usr/bin/python2.7 /usr/lib64/python2.7/site-packages/pip/__init__.py install puppetboard',
    creates => $puppetboard_dir,
  } ->
  file { '/etc/nginx/conf.d':
    ensure => directory
  } ->
  class { 'nginx': } ->
  exec { 'nginx-add-conf.d':
    command => '/bin/sed --in-place -e "s@include /etc/nginx/mime.types;@include /etc/nginx/mime.types;\n\tinclude /etc/nginx/conf.d/*.conf;@" /etc/nginx/nginx.conf',
    unless  => '/bin/grep "include /etc/nginx/conf.d/\*.conf;" /etc/nginx/nginx.conf',
  } ~>
  exec { 'restart-nginx-after-conf':
    command     => '/etc/init.d/nginx restart',
    refreshonly => true
  }

  nginx::resource::upstream { 'puppetboard':
    ensure  => present,
    members => [
      '127.0.0.1:9090',
    ]
  } ->
  file { '/var/www/puppet.vagrant.local':
    ensure => directory,
    owner  => 'root',
    group  => 'nobody',
    mode   => '0766',
  } ->
  nginx::resource::vhost { 'puppet.vagrant.local' :
    listen_ip          => '0.0.0.0',
    default_server     => true,
    www_root           => '/var/www/puppet.vagrant.local',
    template_directory => '/vagrant/manifests/profile/templates/puppet/nginx_location.conf.erb',
  } ->
  group { 'puppetboard':
    ensure => present,
    system => true,
  } ->
  user { 'puppetboard':
    ensure => present,
    system => true,
    gid    => 'puppetboard',
  } ->
  file { '/var/log/puppetboard/':
    ensure => directory,
    owner  => 'puppetboard',
    group  => 'puppetboard',
  } ->
  augeas { 'puppetboard-uwsgi':
    context => '/files/etc/conf.d/uwsgi.puppetboard',
    lens    => 'Shellvars.lns',
    incl    => '/etc/conf.d/uwsgi.puppetboard',
    changes => [
      'set UWSGI_USER puppetboard',
      'set UWSGI_GROUP puppetboard',
      'set UWSGI_LOG_FILE /var/log/puppetboard/uwsgi.log',
      'set UWSGI_DIR /var/www/puppet.vagrant.local',
      "set UWSGI_EXTRA_OPTIONS '\"--http 127.0.0.1:9090 --uwsgi-socket 127.0.0.1:9091 --plugin python27 --wsgi-file ${wsgi_script}\"'",
    ]
  } ->
  file { $wsgi_script:
    ensure  => file,
    content => 'from puppetboard.app import app as application',
    mode    => '0644',
  } ->
  file { '/etc/init.d/uwsgi.puppetboard':
    ensure => link,
    target => '/etc/init.d/uwsgi',
  } ->
  service { 'uwsgi.puppetboard':
    ensure  => running,
    enable  => true,
    require => [
      Class['nginx'],
      Service['puppetmaster']
    ]
  }

  # puppetmaster
  package_use { 'app-admin/puppet':
    ensure => present,
    use    => [
      'augeas',
      'diff',
      'doc',
      'shadow',
      'vim-syntax'
    ]
  } ->
  package { 'app-admin/puppet':
    ensure => installed,
  } ->
  augeas {
    'puppet main setup':
      context => '/files/etc/puppet/puppet.conf/main',
      changes => [
        'set modulepath /vagrant/modules',
        'set manifestdir /vagrant/manifests',
        'set manifest /vagrant/manifests/site.pp',
        'set pluginsync true',
        'set parser future',
      ];
    'puppet master setup':
      context => '/files/etc/puppet/puppet.conf/master',
      changes => [
        "set server ${::fqdn}",
        'set reports store,puppetdb',
        'set storeconfigs true',
        'set storeconfigs_backend puppetdb',
        'set autosign true',
      ];
    'puppet agent config':
      context => '/files/etc/puppet/puppet.conf/agent',
      changes => [
        "set certname ${::fqdn}",
      ];
    'puppetdb puppet config':
      context => '/files/etc/puppet/puppetdb.conf/main',
      lens    => 'Puppet.lns',
      incl    => '/etc/puppet/puppetdb.conf',
      changes => [
        "set server ${::fqdn}",
      ];
    'puppetdb routes config':
      context => '/files/etc/puppet/routes.yaml/master/facts',
      changes => [
        'set terminus puppetdb',
        'set cache yaml',
      ];
    'puppetdb jetty config':
      context => '/files/etc/puppetdb/conf.d/jetty.ini/jetty',
      lens    => 'Puppet.lns',
      incl    => '/etc/puppetdb/conf.d/jetty.ini',
      changes => [
        'set host 0.0.0.0',
      ],
      require => Package['app-admin/puppetdb'];
  } ~>
  service { 'puppetmaster':
    ensure => running,
    enable => true,
  }
  Service['puppetmaster'] -> Exec['puppetdb-ssl-setup']

  exec { 'run-puppet-agent-once':
    command     => '/usr/bin/puppet agent --test --noop',
    refreshonly => true
  } ->
  exec { 'puppetdb-ssl-setup':
    command => '/usr/sbin/puppetdb-ssl-setup',
    creates => [
      '/etc/puppetdb/ssl/ca.pem',
      '/etc/puppetdb/ssl/private.pem',
      '/etc/puppetdb/ssl/public.pem',
    ],
    notify  => Service['puppetdb'],
  #} ->
  #service { 'puppet':
  #  ensure => running,
  #  enable => true,
  }
}
