require 'test/unit'
require File.dirname(__FILE__) + '/../lib/iso7816'

class TestAPDU < Test::Unit::TestCase

  def setup
  end
  
  def s2b str
    ISO7816.s2b str
  end

  def test_store_data_security_level
    mock_ctx = Object.new
    mock_ctx.class.class_eval{
      attr_accessor :level
    }

    [:no_sec, :mac, :enc_and_mac].each {|lev|
           mock_ctx.level=lev
           sd = EMV::APDU::CPS::STORE_DATA.new nil, mock_ctx
           assert_equal lev, sd.security_level
           case lev
           when :no_sec, :mac
             assert !sd.secure?
           else
             assert sd.secure?
           end

           sd.security_level = :no_sec
           assert !sd.secure? 
           sd.security_level = :mac
           assert !sd.secure? 
           sd.security_level = :enc_and_mac
           assert sd.secure? 
    }
    assert true
  end
end
