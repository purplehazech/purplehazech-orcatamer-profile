# -*- mode: ruby -*-
# vi: set ft=ruby :
#                                      _                                  
#                                     ( )_                                
#              _    _ __   ___    _ _ | ,_)   _ _   ___ ___     __   _ __ 
#            /'_`\ ( '__)/'___) /'_` )| |   /'_` )/' _ ` _ `\ /'__`\( '__)
#           ( (_) )| |  ( (___ ( (_| || |_ ( (_| || ( ) ( ) |(  ___/| |   
#           `\___/'(_)  `\____)`\__,_)`\__)`\__,_)(_) (_) (_)`\____)(_)   
#
# ======================================================================================
#
#                 MODERN PUPPET INFRASTRUCTURE ON GENTOO WITH STYLE
#
# ======================================================================================
#

forge "http://forge.puppetlabs.com"

modulefile

# nodejs for boxes like the pump.io box
mod "puppetlabs/nodejs",
  :git => 'https://github.com/hairmare/puppetlabs-nodejs.git',
  :ref => 'feature/gentoo'

# mongodb for various servers and clients
mod "example42/mongodb"

# openssl for managing certs for various apps
mod "camptocamp/openssl"
