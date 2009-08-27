$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require '7816/card'
require '7816/atr'
require '7816/apdu'
require '7816/iso_apdu'
require '7816/pcsc_helper'

