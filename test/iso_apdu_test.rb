require 'test/unit'
require File.dirname(__FILE__) + '/../lib/iso7816'

class TestAPDU < Test::Unit::TestCase

  def setup
  end
  
  def s2b str
    ISO7816.s2b str
  end

  def test_apdus
    ISO7816::APDU::ACTIVATE_FILE.new
    ISO7816::APDU::APPEND_RECORD.new
    ISO7816::APDU::CHANGE_REFERENCE_DATA.new
    ISO7816::APDU::CREATE_FILE.new
    ISO7816::APDU::DEACTIVATE_FILE.new
    ISO7816::APDU::DELETE_FILE.new
    ISO7816::APDU::DISABLE_VERIFICATION_REQUIREMENT.new
    ISO7816::APDU::ENABLE_VERIFICATION_REQUIREMENT.new
    ISO7816::APDU::ENVELOPE.new
    ISO7816::APDU::ERASE_BINARY.new
    ISO7816::APDU::ERASE_RECORD.new
    ISO7816::APDU::EXTERNAL_AUTHENTICATE.new
    ISO7816::APDU::GENERAL_AUTHENTICATE.new
    ISO7816::APDU::GENERATE_ASYMMETRIC_KEY_PAIR.new
    ISO7816::APDU::GET_CHALLENGE.new
    ISO7816::APDU::GET_DATA.new
    ISO7816::APDU::GET_RESPONSE.new
    ISO7816::APDU::INTERNAL_AUTHENTICATE.new
    ISO7816::APDU::MANAGE_CHANNEL.new
    ISO7816::APDU::MANAGE_SECURITY_ENVIRONMENT.new
    ISO7816::APDU::PERFORM_SCQL_OPERATION.new
    ISO7816::APDU::PERFORM_SECURITY_OPERATION.new
    ISO7816::APDU::PERFORM_TRANSACTION_OPERATION.new
    ISO7816::APDU::PERFORM_USER_OPERATION.new
    ISO7816::APDU::PUT_DATA.new
    ISO7816::APDU::READ_BINARY.new
    ISO7816::APDU::READ_RECORD.new
    ISO7816::APDU::RESET_RETRY_COUNTER.new
    ISO7816::APDU::SEARCH_BINARY.new
    ISO7816::APDU::SEARCH_RECORD.new
    ISO7816::APDU::SELECT.new
    ISO7816::APDU::TERMINATE_CARD_USAGE.new
    ISO7816::APDU::TERMINATE_DF.new
    ISO7816::APDU::TERMINATE_EF.new
    ISO7816::APDU::UPDATE_BINARY.new
    ISO7816::APDU::UPDATE_RECORD.new
    ISO7816::APDU::VERIFY.new
    ISO7816::APDU::WRITE_BINARY.new
    ISO7816::APDU::WRITE_RECORD.new
    assert true
  end

  def test_proper_ins
    test_data = [
      [ISO7816::APDU::ACTIVATE_FILE,                     "\x44"],
      [ISO7816::APDU::APPEND_RECORD,                     "\xE2"],
      [ISO7816::APDU::CHANGE_REFERENCE_DATA,             "\x24"],
      [ISO7816::APDU::CREATE_FILE,                       "\xE0"],
      [ISO7816::APDU::DEACTIVATE_FILE,                   "\x04"],
      [ISO7816::APDU::DELETE_FILE,                       "\xE4"],
      [ISO7816::APDU::DISABLE_VERIFICATION_REQUIREMENT,  "\x26"],
      [ISO7816::APDU::ENABLE_VERIFICATION_REQUIREMENT,   "\x28"],
      [ISO7816::APDU::ENVELOPE,                          "\xC2"],
      [ISO7816::APDU::ERASE_BINARY,                      "\x0E"],
      [ISO7816::APDU::ERASE_RECORD,                      "\x0C"],
      [ISO7816::APDU::EXTERNAL_AUTHENTICATE,             "\x82"],
      [ISO7816::APDU::GENERAL_AUTHENTICATE,              "\x86"],
      [ISO7816::APDU::GENERATE_ASYMMETRIC_KEY_PAIR,      "\x46"],
      [ISO7816::APDU::GET_CHALLENGE,                     "\x84"],
      [ISO7816::APDU::GET_DATA,                          "\xCA"],
      [ISO7816::APDU::GET_RESPONSE,                      "\xC0"],
      [ISO7816::APDU::INTERNAL_AUTHENTICATE,             "\x88"],
      [ISO7816::APDU::MANAGE_CHANNEL,                    "\x70"],
      [ISO7816::APDU::MANAGE_SECURITY_ENVIRONMENT,       "\x22"],
      [ISO7816::APDU::PERFORM_SCQL_OPERATION,            "\x10"],
      [ISO7816::APDU::PERFORM_SECURITY_OPERATION,        "\x2A"],
      [ISO7816::APDU::PERFORM_TRANSACTION_OPERATION,     "\x12"],
      [ISO7816::APDU::PERFORM_USER_OPERATION,            "\x14"],
      [ISO7816::APDU::PUT_DATA,                          "\xDA"],
      [ISO7816::APDU::READ_BINARY,                       "\xB0"],
      [ISO7816::APDU::READ_RECORD,                       "\xB2"],
      [ISO7816::APDU::RESET_RETRY_COUNTER,               "\x2C"],
      [ISO7816::APDU::SEARCH_BINARY,                     "\xA0"],
      [ISO7816::APDU::SEARCH_RECORD,                     "\xA2"],
      [ISO7816::APDU::SELECT,                            "\xA4"],
      [ISO7816::APDU::TERMINATE_CARD_USAGE,              "\xFE"],
      [ISO7816::APDU::TERMINATE_DF,                      "\xE6"],
      [ISO7816::APDU::TERMINATE_EF,                      "\xE8"],
      [ISO7816::APDU::UPDATE_BINARY,                     "\xD6"],
      [ISO7816::APDU::UPDATE_RECORD,                     "\xDC"],
      [ISO7816::APDU::VERIFY,                            "\x20"],
      [ISO7816::APDU::WRITE_BINARY,                      "\xD0"],
      [ISO7816::APDU::WRITE_RECORD,                      "\xD2"]
     ]

     test_data.each {|ins_|
      clazz, ins = ins_
      assert_equal ins, clazz._ins
      apdu = clazz.new
      assert_equal ins, apdu.ins
     }
  end
end
