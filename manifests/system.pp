# # Class: profile::system
#
# Basic profile that gets applied on all systems.
#
class profile::system {

  file {
    # these must exists even on an empty repo
    # after running this the first time it
    # should get populated by binaries that
    # make subsequentive runs much faster
    '/vagrant/portage':
      ensure => directory;
    '/vagrant/portage/packages':
      ensure => directory;
    '/etc/puppet/hiera.yaml':
      ensure  => file,
      content => 'version: 2',
      mode    => '0744';
    # to make life easier for developers we create an
    # empty local overlay
    '/usr/local/portage/':
      ensure  => directory;
    '/usr/local/portage/make.conf':
      ensure  => file;
    '/usr/local/portage/metadata':
      ensure  => directory;
    '/usr/local/portage/metadata/layout.conf':
      ensure  => file,
      content => 'masters = gentoo';
  } ->
  class { '::sudo':
  } ->
  sudo::conf { 'vagrant':
    priority => 10,
    content  => 'vagrant ALL=NOPASSWD: ALL',
  } ->
  package { 'net-misc/curl':
    # we always want curl, it is used by git for http URLs for instance
    ensure => present;
  } ->
  # manage /etc/portage/make.conf
  portage::makeconf {
    'portdir_overlay':
      ensure  => present,
      # enable local overlay (this is a dev box after all)
      content => '/usr/local/portage';
    'source /usr/local/portage/make.conf':
      ensure => present;
    'features':
      ensure  => present,
      content => [
        'sandbox',
        'parallel-fetch',
        # activate binary package building
        'buildpkg',
        'buildsyspkg',
        # use binary packages when available
        'getbinpkg',
      ];
    'use':
      ensure  => present,
      content => [
        'nls',
        'cjk',
        'unicode'
      ];
    'pkgdir':
      ensure  => present,
      content => '/vagrant/portage/packages';
    'portage_binhost':
      ensure  => present,
      content => [
        'http://bindist.hairmare.ch/gentoo-dev/portage/packages/',
      ];
    'python_targets':
      ensure  => present,
      content => [
        'python2_7',
        'python3_2',
        'python3_3',
      ];
    'use_python':
      ensure  => present,
      content => [
        '3.2',
        '2.7',
      ];
    'ruby_targets':
      ensure  => present,
      content => [
        'ruby18',
        'ruby19',
        'ruby20',
      ];
    'linguas':
      ensure  => present,
      content => [
        'en',
      ];
    # so we don't need bindist due to openssl
    'curl_ssl':
      ensure  => present,
      content => 'gnutls';
    # these are currently setup for virtualbox support
    'input_devices':
      ensure  => present,
      content => [
        'evdev',
      ];
    'video_cards':
      ensure  => present,
      content => [
        'virtualbox',
      ];
  } -> Class['ccache']

  portage::package { 'dev-vcs/git':
    ensure => present,
    use    => [
      'curl',
    ],
  } ->
  # install most portage tools
  class { 'portage':
    # bump eix due to bugs with --format '<bestversion:LASTVERSION>' in 0.29.0
    eix_ensure           => '0.30.0',
    eix_keywords         => ['~amd64'],
    layman_ensure        => present,
    webapp_config_ensure => present,
    eselect_ensure       => present,
    portage_utils_ensure => present
  } ->
  exec { 'sync-layman':
    command     => '/usr/bin/layman -S',
    refreshonly => true,
    subscribe   => Package['app-portage/layman'],
  } ->
  # install ccache since these are dev/build boxes
  class { 'ccache':
  } ->
  class { 'syslogng':
    logpaths     => {
      'syslog-ng'     => {},
      'sshd'          => {},
      'sudo'          => {},
      'puppet-agent'  => {},
      'puppet-master' => {},
    },
    destinations => {
      '10.30.0.30' => {
        type      => 'syslog',
        transport => 'udp',
        logpaths  => {
          'syslog-ng'     => {},
          'sshd'          => {},
          'sudo'          => {},
          'puppet_agent'  => {},
          'puppet_master' => {},
        },
      },
      'messages'   => {}
    },
  } ->
  # remove any other sysloggers (from veewee or stage3)
  service { [ 'metalog', 'rsyslog' ]:
    ensure => stopped,
  } ->
  package { [ 'metalog', 'rsyslog' ]:
    ensure => absent,
  }

  # setup augeas 1.x
  package_keywords { 'app-admin/augeas':
    ensure   => present,
    keywords => [
      '~amd64',
    ],
    version  => '=1.1.0'
  } ~>
  package { 'app-admin/augeas':
    ensure => installed,
  }

  # some flags that make more sense here than in puppet or elasticsearch
  # in the long run they will move though
  package_use {
    'x11-libs/cairo':
      ensure => present,
      use    => [
        'X'
      ];
    'app-text/ghostscript-gpl':
      ensure => present,
      use    => [
        'cups',
      ];
  }
}
