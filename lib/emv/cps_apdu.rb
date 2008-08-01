module EMV 
module APDU
module CPS

class CPS_APDU < EMV::APDU::EMV_APDU
  attr_accessor :kenc
  attr_accessor :ini_response
  attr_accessor :ses_key_enc
  def initialize card=nil, kenc="\x00"*16
    super card
    @kenc= kenc
  end
end
class INITIALIZE_UPDATE < CPS_APDU 
  def initialize card=nil, kenc="\x00"*16
    super 
    @ins="\x50"
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
    @ses_key_enc = EMV::Crypto.generate_session_key(kenc, @ini_response.seq_counter, :enc)
    mac_         = data + @ini_response.seq_counter + @ini_response.challenge
    mac          = EMV::Crypto.mac_for_personalization(@ses_key_enc, mac_)
    raise "invalid MAC returned from card!" unless mac == @ini_response.cryptogram
  end
end
class C_MAC_APDU < CPS_APDU
  attr_accessor :prev_c_mac
  attr_accessor :c_mac
  def initialize card, prev
    super card, prev.kenc
    self.prev_c_mac = prev.c_mac if prev.is_a? C_MAC_APDU
  end
end
class EXTERNAL_AUTHENTICATE < CPS_APDU 
  # the INITIALIZE UPDATE cmd that preceeded this EXT AUTH
  attr_accessor :initialize_update

  def initialize card, init_update
    super
    @cla="\x84"
    @ins="\x82"
    @initialize_update = init_update
    @ini_response = @initialize_update.ini_response
    @ses_key_enc  = @initialize_update.ses_key_enc

  end

  #
  # CPS 3.2.6
  #   :enc_and_mac
  #   :mac
  #   :no_sec
  #   or a sec level byte...
  def security_level= level
    case level
      when :enc_and_mac 
        p1= 0x03
      when :mac
        p1= 0x01
      when :no_sec
        p1= 0x00
      else
        p1=level  
    end
  end
  
  # 
  # Sets the host cryptogram according to CPS 3.2.6.6
  # takes either one parameter, the calculated cryptogram data, or
  # the cryptogram is calculated 
  #
  def cryptogram 
    return @cryptogram if @cryptogram

    mac_ = @ini_response.seq_counter + 
           @ini_response.challenge +
           @initialize_update.challenge
    mac  = EMV::Crypto.mac_for_personalization(@ses_key_enc, mac_)
    
    @cryptogram = mac
    @cryptogram
  end

  def cryptogram= bytes
    @cryptogram= bytes
  end

  # calculate the c-mac according to 5.4.2.2
  def c_mac
    return @c_mac if @c_mac
    # data with placeholder for cmac      
    self.data= cryptogram + "\x00"*8
    bytes = to_b
    bytes = bytes[0, bytes.length-8] # command header with data, excl. cmac
    
    @c_mac = EMV::Crypto.retail_mac(bytes) 
    self.data= cryptogram + @c_mac
    @c_mac  
  end          

  def c_mac= bytes
    self.data= cryptogram + bytes
  end 
end
class STORE_DATA < EMV::APDU::EMV_APDU

  LAST_STORE_DATA_MASK = 0x80
  ALL_DGI_ENC_MASK =     0x60
  NO_DGI_ENC_MASK =      0x00
  APP_DEPENDANT_MASK =   0x20

  SECURE_MASK = 0x04

  def initialize card=nil
    super
    @ins="\xE2"
  end
  def secure
    self.cla= cla[0] | SECURE_MASK
  end
  def secure?
    (cla[0] & SECURE_MASK) == SECURE_MASK     
  end
  def last_store_data
    self.p1= (p1[0] | LAST_STORE_DATA_MASK)
  end
  def last_store_data?
    (p1[0] & LAST_STORE_DATA_MASK) == LAST_STORE_DATA_MASK
  end
  def all_dgi_enc
    self.p1= (p1[0] | ALL_DGI_ENC_MASK)
  end
  def all_dgi_enc?
    (p1[0] & ALL_DGI_ENC_MASK) == ALL_DGI_ENC_MASK
  end
  def no_dgi_enc
    self.p1= (p1[0] & ~ ALL_DGI_ENC_MASK)
  end
  def no_dgi_enc?
    (p1[0] & NO_DGI_ENC_MASK) == NO_DGI_ENC_MASK
  end
  def app_dependant
    self.p1= (p1[0] & ~ ALL_DGI_ENC_MASK) | APP_DEPENDANT_MASK
  end
  def app_dependant?
    (p1[0] & APP_DEPENDANT_MASK) == APP_DEPENDANT_MASK
  end

end

end #CPS
end # APDU
end #EMV
