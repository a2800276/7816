module EMV 

module APDU

class EMV_APDU < ISO7816::APDU::APDU
  def initialize card=nil
    super
    @cla="\x80"
  end
end

def APDU.create_class name, ins
cl=
%Q(
class #{name} < EMV_APDU
  def initialize card= nil
    super
    @ins= \"\\x#{ins}\"
  end
end
)
      eval(cl)
end
[
["APPLICATION_BLOCK", "1E"],
["APPLICATION_UNBLOCK", "18"],
["CARD_BLOCK", "16"],
["GENERATE_APPLICATION_CRYPTOGRAM", "AE"],
["GET_DATA", "CA"],
["GET_PROCESSING_OPTIONS", "A8"],
["PIN_CHANGE_UNBLOCK", "24"],
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
end
class VERIFY < ISO7816::APDU::VERIFY
end

end # APDU

end #EMV
