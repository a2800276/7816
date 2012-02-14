require 'test/unit'
require File.dirname(__FILE__) + '/../lib/emv/crypto/crypto'

class CryptoTest < Test::Unit::TestCase

  def setup
  end
  
  def s2b str
    ISO7816.s2b str
  end

  def test_retail_mac
    key   = s2b '7962D9ECE03D1ACD4C76089DCE131543'
    input = s2b '72C29C2371CC9BDB65B779B8E8D37B29ECC154AA56A8799FAE2F498F76ED92F2'

    mac   = s2b '5F1448EEA8AD90A7' 
    assert_equal mac, EMV::Crypto.retail_mac(key, input)


  end

end
