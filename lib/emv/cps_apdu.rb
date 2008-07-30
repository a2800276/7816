module EMV 
module APDU
module CPS

class INITIALIZE_UPDATE < EMV::APDU::EMV_APDU
  def initialize card=nil
    super
    @ins="\x50"
  end
end
class EXTERNAL_AUTHENTICATE < EMV::APDU::EXTERNAL_AUTHENTICATE
  def initialize card=nil
    super
    @cla="\x84"
    @ins="\x82"
  end
end
class STORE_DATA < EMV::APDU::EMV_APDU
  def initialize card=nil
    super
    @ins="\xE2"
  end
end

end #CPS
end # APDU
end #EMV
