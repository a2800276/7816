require 'test/unit'
require File.dirname(__FILE__) + '/../lib/iso7816'

class TestUtils < Test::Unit::TestCase

  def setup
  end
  
  def s2b str
    ISO7816.s2b str
  end

  def tests2b 
    str = "aa aa aa aa aa"
    assert_equal "\xaa\xaa\xaa\xaa\xaa", ISO7816.s2b(str)
  
    str = str.upcase
    assert_equal "\xaa\xaa\xaa\xaa\xaa", ISO7816.s2b(str)

    str.gsub! /\s+/, ""
    assert_equal "\xaa\xaa\xaa\xaa\xaa", ISO7816.s2b(str)
  end

  def testb2s
    str = "\xaa\xaa\xaa\xaa"
    assert_equal "aaaaaaaa", ISO7816.b2s(str)

  end

 end
