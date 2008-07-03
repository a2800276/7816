require 'test/unit'
require File.dirname(__FILE__) + '/../lib/iso7816'

class TestAPDU < Test::Unit::TestCase

  def setup
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
end
