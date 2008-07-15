require 'test/unit'
require File.dirname(__FILE__) + '/../lib/iso7816'

class TestAPDU < Test::Unit::TestCase

  def setup
  end
  
  def s2b str
    ISO7816.s2b str
  end

  def test_select
#    s = ISO7816::APDU::SELECT_FILE.new
#    
#    assert s.to_b == "\x00\xa4\x00\x00"
#    assert s.to_b == "\x00\xa4\x00\x00"
#    assert s.to_s == "|CLA|INS| P1| P2|\n| 00| a4| 00| 00|"
#    
#    # add filename
#    
#    s.data = "\x37\x00"
#    assert s.to_b == "\x00\xa4\x00\x00\x02\x37\x00"
#    assert s.to_s == "|CLA|INS| P1| P2|| LC|Data| LE|\n| 00| a4| 00| 00|| 02|3700|   |"
     assert true
  end
  def test_invalid_ins
    apdu = ISO7816::APDU::APDU.new
    ["\x90", "\x95", "\x9f", "\x60", "\x65", "\x6f"]. each {|inv|
      apdu.ins=inv
      assert_equal false, apdu.ins_valid?
    }
    ["\x10", "\x25", "\x3f", "\x40", "\x55", "\xff"]. each {|inv|
      apdu.ins=inv
      assert_equal true, apdu.ins_valid?
    }

  end

  def test_basics
    a = ISO7816::APDU::APDU.new "test-card"
    assert_equal "\x00", a.cla
    assert_equal "\x00", a.ins
    assert_equal "\x00", a.p1
    assert_equal "\x00", a.p2
    assert_equal "", a.data
    assert_equal "", a.le
    assert_equal "test-card", a.card

    assert_nothing_raised {
      a.to_s
      a.to_b
    }
    
    a = ISO7816::APDU::RandomAPDU.new "test-card"
    [a.cla, a.ins, a.p1, a.p2].each {|by|
      assert_not_equal nil, by
      assert_equal 1, by.length
    }
    assert_equal true, a.ins_valid?
    
    assert_equal "", a.data
    assert_equal "test-card", a.card
    
    assert_nothing_raised {
      a.to_s
      a.to_b
    }
  end
  def test_to_apdu
    apdu = ISO7816::APDU::APDU.to_apdu(s2b("80b4000008"))
    assert_equal "\x80", apdu.cla
    assert_equal "\xb4", apdu.ins
    assert_equal "\x00", apdu.p1
    assert_equal "\x00", apdu.p2
    assert_equal "\x08", apdu.le
    
    apdu = ISO7816::APDU::APDU.to_apdu(s2b("8020000008aaaaaaaaaaaaaaaa"))
    assert_equal "\x80", apdu.cla
    assert_equal "\x20", apdu.ins
    assert_equal "\x00", apdu.p1
    assert_equal "\x00", apdu.p2
    assert_equal "\x08", apdu.lc
    assert_equal "\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa", apdu.data

    assert_raise(RuntimeError){
      apdu = ISO7816::APDU::APDU.to_apdu(s2b("8020000008aaaaaaaaaaaaaaaaaaaa"))
    }

    apdu = ISO7816::APDU::APDU.to_apdu(s2b("fefefefefe"))
    assert_equal "\xfe", apdu.cla
    assert_equal "\xfe", apdu.ins
    assert_equal "\xfe", apdu.p1
    assert_equal "\xfe", apdu.p2
    assert_equal "\xfe", apdu.le
    assert_equal "", apdu.lc
    assert_equal "", apdu.data

  end
end
