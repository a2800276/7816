$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'iso7816'
require 'emv/emv'
require 'emv/emv_apdu'
require 'emv/cps_apdu'
require 'emv/data/cps_ini_update'
require 'emv/crypto/crypto'

