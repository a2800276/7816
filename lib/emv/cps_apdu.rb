module EMV 
module APDU
module CPS

class INITIALIZE_UPDATE < EMV::APDU::EMV_APDU
  attr_accessor :ini_response
  attr_accessor :kenc
  def initialize card=nil, kenc="\x00"*16
    super card
    @ins="\x50"
    @kenc=kenc
  end

  def challenge= challenge
    @data=challenge
  end
  def send handle_more_data=true, card=nil
    resp = super
    @ini_response = EMV::Data::InitializeUpdateData.new(resp.data) if resp.status == "9000"
    check_cryptogram
    resp
  end

  def check_cryptogram
    return unless @ini_response
    ses_key = EMV::Crypto.generate_session_key(kenc, @ini_response.seq_counter, :enc)
    mac_    = data + @ini_response.seq_counter + @ini_response.challenge
    mac     = EMV::Crypto.mac_for_personalization(ses_key, mac_)
    raise "invalid MAC returned from card!" unless mac == @ini_response.cryptogram
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
