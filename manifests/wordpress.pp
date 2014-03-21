# # Class: profile::wordpress
#
#
class profile::wordpress {
  package_use { 'app-admin/eselect-php':
    use => [
      'fpm',
    ]
  } ->
  package_use { 'dev-lang/php':
    use => [
      'gd',
      'truetype',
      'fpm',
      'mysql',
    ]
  } ->
  portage::package { 'www-apps/wordpress':
    ensure   => installed,
    alias    => 'wordpress',
    use      => [
      'vhosts'
    ],
    keywords => [
      '~amd64',
    ],
  }
}
