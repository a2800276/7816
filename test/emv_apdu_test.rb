require 'test/unit'
require File.dirname(__FILE__) + '/../lib/emv'

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
    ctx = EMV::APDU::CPS::SecureContext.new

    EMV::APDU::CPS::INITIALIZE_UPDATE.new nil, ctx
    EMV::APDU::CPS::EXTERNAL_AUTHENTICATE.new nil, ctx
    sd = EMV::APDU::CPS::STORE_DATA.new nil, ctx
    assert_equal "\x00", sd.p1
    sd.last_store_data
    assert_equal "\x80", sd.p1
     
    assert sd.no_dgi_enc?
    sd.app_dependant
    assert sd.app_dependant?
    assert_equal "\xa0", sd.p1
    assert !sd.all_dgi_enc?
    sd.all_dgi_enc
    assert_equal "\xe0", sd.p1

    
    assert !sd.secure?
    sd.secure
    assert sd.secure?
    
  end

  def test_generated
    test_data = [
      [EMV::APDU::APPLICATION_BLOCK, "\x1E", "\x84"],
      [EMV::APDU::APPLICATION_UNBLOCK, "\x18", "\x84"],
      [EMV::APDU::CARD_BLOCK, "\x16", "\x84"],
      [EMV::APDU::GENERATE_APPLICATION_CRYPTOGRAM, "\xAE", "\x80"],
      [EMV::APDU::GET_DATA, "\xCA", "\x80"],
      [EMV::APDU::GET_PROCESSING_OPTIONS, "\xA8", "\x80"],
      [EMV::APDU::PIN_CHANGE_UNBLOCK, "\x24", "\x84"],
    ]

    test_data.each {|ins_|
      clazz, ins, cla = ins_
      assert_equal ins, clazz._ins
      assert_equal cla, clazz._cla, clazz
      apdu = clazz.new
      assert_equal ins, apdu.ins
      assert_equal cla, apdu.cla
    }

  end
end
