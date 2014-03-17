# # Class: profile::mongodb
#
#
class profile::mongodb {
  class { 'mongodb':
    server_package_name => 'mongodb',
    client_package_name => false,
  }
}
