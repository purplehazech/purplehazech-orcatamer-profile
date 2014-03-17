# # Class: profile::mongodb
#
#
class profile::mongodb {
  class { '::mongodb':
    package        => 'mongodb',
    package_client => false,
  }
}
