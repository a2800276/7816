module EMV 

module APDU

class EMV_APDU < ISO7816::APDU::APDU
  cla "\x80"
end

def APDU.create_class name, ins, cla="80"
  cl =  "class #{name} < EMV_APDU\n"
  cl << "  cla \"\\x#{cla}\"\n" unless cla == "80"
  cl << "  ins \"\\x#{ins}\"\n"
  cl << "end"

   eval(cl)
end
[
["APPLICATION_BLOCK", "1E", "84"],
["APPLICATION_UNBLOCK", "18", "84"],
["CARD_BLOCK", "16", "84"],
["GENERATE_APPLICATION_CRYPTOGRAM", "AE"],
["GET_DATA", "CA"],
["GET_PROCESSING_OPTIONS", "A8"],
["PIN_CHANGE_UNBLOCK", "24", "84"],
].each{|entry|
  APDU.create_class *entry
}


class EXTERNAL_AUTHENTICATE < ISO7816::APDU::EXTERNAL_AUTHENTICATE
end
class GET_CHALLENGE < ISO7816::APDU::GET_CHALLENGE
end
class INTERNAL_AUTHENTICATE < ISO7816::APDU::INTERNAL_AUTHENTICATE
end
class READ_RECORD < ISO7816::APDU::READ_RECORD
end
class SELECT < ISO7816::APDU::SELECT
  p1 "\x04"
end
class VERIFY < ISO7816::APDU::VERIFY
  def initialize card 
    super
    self.plaintext_pin
  end
  def plaintext_pin
    @p2 = ("" << 0x80)
  end  
  def enciphered_pin
    @p2 = ("" << 0x88)
  end
end

end # APDU

end #EMV
