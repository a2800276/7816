require 'test/unit'
require File.dirname(__FILE__) + '/../lib/iso7816'

class TestEMV_APDU < Test::Unit::TestCase

  def setup
  end
  
  def s2b str
    ISO7816.s2b str
  end

  def test_apdus
    EMV::APDU::APPLICATION_BLOCK.new
    EMV::APDU::APPLICATION_UNBLOCK.new
    EMV::APDU::CARD_BLOCK.new
    EMV::APDU::GENERATE_APPLICATION_CRYPTOGRAM.new
    EMV::APDU::GET_DATA.new
    EMV::APDU::GET_PROCESSING_OPTIONS.new
    EMV::APDU::PIN_CHANGE_UNBLOCK.new

    EMV::APDU::EXTERNAL_AUTHENTICATE.new ""
    EMV::APDU::GET_CHALLENGE.new ""
    EMV::APDU::INTERNAL_AUTHENTICATE.new ""
    EMV::APDU::READ_RECORD.new ""
    EMV::APDU::SELECT.new ""
    EMV::APDU::VERIFY.new ""
    
    assert true

  end

  def test_cps_apdus
    EMV::APDU::CPS::INITIALIZE_UPDATE.new
    EMV::APDU::CPS::EXTERNAL_AUTHENTICATE.new
    EMV::APDU::CPS::STORE_DATA.new
    assert true
  end
end
