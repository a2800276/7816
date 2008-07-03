require 'test/unit'
require File.dirname(__FILE__) + '/../lib/iso7816'

class TestResponse < Test::Unit::TestCase

  def setup
  end
  
  def test_resp_basics
    
    response = ISO7816::APDU::Response

    r = response.new "\x90\x00"
    assert r.normal?
    assert r.data == ""

    r = response.new "blabla\x90\x00", 6
    assert r.normal?


    r = response.new "blabla\x61\xff", 6
    assert r.normal?

    ["\x62","\x63"].each {|byte|
      r = response.new "bla#{byte}#{byte}", 3
      assert r.warning?
    }
    
    ["\x64", "\x65", "\x66"].each_with_index {|byte, i|
      r= response.new "#{'a'*i}#{byte}\x00", i
      assert r.execution_err?
    }

    ["\x67", "\x68", "\x69", "\x6a", "\x6b", "\x6c", "\x6d", "\x6e", "\x6f"].each_with_index { |byte, i|
      r= response.new "#{'a'*i}#{byte}\x00", i
      assert r.checking_err?
      assert r.data  == 'a'*i
    }
  end
  
  # these are a tad contrived and are only meant to ensure basic coverage...
  def test_resp_to_s
    response = ISO7816::APDU::Response
    r = response.new "\x90\x00"
    assert r.to_s ==  "APDU Response\n  SW1: 90 (OK: No further qualification)\n  SW2: 00 ()\n"

    r = response.new "blabla\x61\xff"
    assert r.to_s == "APDU Response\n  SW1: 61 (OK: SW2 indicates the number of response bytes still available)\n  SW2: ff (ff bytes remaining.)\n"
    
    r = response.new "bla\x62\62"
    assert r.to_s == "APDU Response\n  SW1: 62 (WARN: State of non-volatile memory unchanged)\n  SW2: 32 (unknown sw2 for sw1=62: 32)\n"
    
    r = response.new "\x63\x81"
    assert r.to_s == "APDU Response\n  SW1: 63 (WARN: State of non-volatile memory changed)\n  SW2: 81 (File filled up by the last write)\n"

    r = response.new "#{"aa"}\x66\x00", 2
    assert r.to_s ==  "APDU Response\n  Data(2): 6161\n  SW1: 66 (EXE ERR: Reserved for security-related issues)\n  SW2: 00 (security (undefined))\n"
    
    r = response.new "#{"aa"}\x69\x77", 2
    assert r.to_s == "APDU Response\n  Data(2): 6161\n  SW1: 69 (CHK ERR: Command not allowed)\n  SW2: 77 (unknown sw2 for sw1=69: 77)\n"

  end
end
