require 'test/unit'
require File.dirname(__FILE__) + '/../lib/iso7816'

class TestCard < Test::Unit::TestCase
  
  ATR = "\x3b\xd9\x18\x00\x00\x80\x54\x43\x4f\x4c\x44\x82\x90\x00"
  def setup
    @server = Thread.start {
      require 'socket'
      ssock = TCPServer.open(1024)
      while (s = ssock.accept)
        s.send ATR, 0
      end #while
      ssock.close
    }
  end
  
  def teardown
          puts @server.class
    @server.exit
  end
  
  def test_connect
    card = ISO7816::Card::TCPCard.new
    atr = card.connect
    assert_equal true, card.connected
    assert_equal ATR, atr
    card.disconnect
    assert_equal false, card.connected
    
    atr = card.connect {} 
    assert_equal ATR, atr
    assert_equal false, card.connected


  end
end
