module EMV 
module APDU
module CPS


class SecureContext
  # The Kenc key used in this session
  attr_accessor :k_enc

  # The Kmac key used in this session
  attr_accessor :k_mac
  
  # The Kdek key used in this session
  attr_accessor :k_dek

  # The challenge sent to the card, (Rterm)
  attr_accessor :host_challenge

  # The session key SKUenc
  attr_accessor :sku_enc
  
  attr_accessor :sku_mac
  attr_accessor :sku_dek
  
  # The card's response to initialize update containing:
  # kmc_id       		      (Identifier of the KMC)
  # csn   		            (Chip Serial Number)
  # kmc_version 		      (Version Number of Master key (KMC))
  # sec_channel_proto_id 	(Identifier of Secure Channel Protocol)
  # sequence_counter      (Sequence Counter)
  # challenge 		        (Card challenge (r card))
  # cryptogram 		        (Card Cryptogram)

  attr_reader :initialize_response

  # The security level established by the EXTERNAL_AUTH command
  # According to CPS Table 19
  # One of:
  #   :enc_and_mac
  #   :mac
  #   :no_sec
  attr_accessor :level


  def initialize k_enc="\x00"*16, k_mac="\x00"*16, k_dek="\x00"*16, host_challenge="\x00"*8
    @k_enc = k_enc
    @k_mac = k_mac
    @k_dek = k_dek
    
    @host_challenge=host_challenge
    @level = :no_sec
  end

  # Set the response returned by INITIALIZE UPDATE.
  # * calculates the Session keys.
  def initialize_response= resp

    @initialize_response = resp


    @sku_enc = EMV::Crypto.generate_session_key(k_enc, 
                                                @initialize_response.sequence_counter, 
                                                :enc)
    @sku_mac = EMV::Crypto.generate_session_key(k_mac,
                                                @initialize_response.sequence_counter,
                                                :mac)
    
    @sku_dek = EMV::Crypto.generate_session_key(k_dek,
                                                @initialize_response.sequence_counter,
                                                :dek)
  end

  # Verify the cryptogram sent by the card according to: CPS 3.2.5.10
  def check_card_cryptogram
    mac_         = host_challenge + 
                   initialize_response.sequence_counter + 
                   initialize_response.challenge

    mac          = EMV::Crypto.mac_for_personalization(sku_enc, mac_)
    unless mac == initialize_response.cryptogram
      raise %Q{
Invalid MAC returned from card!
host challenge: #{ISO7816.b2s(host_challenge)}
card seq      : #{ISO7816.b2s(initialize_response.sequence_counter)}
card challenge: #{ISO7816.b2s(initialize_response.challenge)}
expected mac  : #{ISO7816.b2s(mac)}
recv mac      : #{ISO7816.b2s(initialize_response.cryptogram)}
k_enc         : #{ISO7816.b2s(k_enc)}
k_mac         : #{ISO7816.b2s(k_mac)}
k_dek         : #{ISO7816.b2s(k_dek)}
      }
    end
  end
  
  # Calculates the host cryptogram according to CPS 3.2.6.6
  def calculate_host_cryptogram
    mac_ = initialize_response.sequence_counter + 
           initialize_response.challenge +
           host_challenge
    EMV::Crypto.mac_for_personalization(sku_enc, mac_)
  end
  
  # Calculate the C-MAC according to CP 5.4.2.2
  def calculate_c_mac apdu
    # data with placeholder for cmac
    data =  apdu.data
    mac_ =  apdu.cla +
            apdu.ins +
            apdu.p1  +
            apdu.p2 
    
    mac_ << apdu.data.length+8
    mac_ << data 
    if @c_mac # "prepend the c-mac computed for the previous command ..."
      mac_ = @c_mac + mac_ 
    end
    @c_mac = EMV::Crypto.retail_mac(sku_mac, mac_) 
    @c_mac  
  end
  
  # Retrieve the current seq number, this also increments the counter.
  def store_data_seq_number
    @store_data_seq_number ||= -1
    @store_data_seq_number += 1
    "" << @store_data_seq_number
  end

  def reset
    @c_mac = nil
    @store_data_seq_number = nil
    @sku_enc = nil
    @sku_mac = nil
    @initialize_response = nil
  end
  
  # Encrypt data bytes according to CPS 5.5.2
  def encrypt data
    data = EMV::Crypto.pad data
    cipher = OpenSSL::Cipher::Cipher.new("des-ede-cbc").encrypt
    cipher.key = sku_enc
    cipher.update data
  end
end

class CPS_APDU < EMV::APDU::EMV_APDU
  attr_accessor :secure_context

  def initialize card, secure_context
    super card
    @secure_context= secure_context
  end
end
class INITIALIZE_UPDATE < CPS_APDU 
  def initialize card, secure_context 
    super 
    @ins="\x50"
  end
  def key_version_number= kvn
    self.p1= kvn
  end
  def send handle_more_data=true, card=nil
    secure_context.reset
    @data = secure_context.host_challenge

    resp = super
    if resp.status == "9000"
        @secure_context.initialize_response = EMV::Data::InitializeUpdateData.new(resp.data)
        @secure_context.check_card_cryptogram
    end
    resp
  end
end

class C_MAC_APDU < CPS_APDU
  # Provides the possibility to override the calculated c_mac
  # with an arbitrary one for testing.
  attr_writer :c_mac

  def initialize card, secure_context
    super
  end

  # calculate the c-mac according to 5.4.2.2
  def c_mac
    @c_mac ||=  secure_context.calculate_c_mac(self) 
    @c_mac  
  end          
end

class EXTERNAL_AUTHENTICATE < C_MAC_APDU 
  def initialize card, secure_context
    super
    @cla="\x84"
    @ins="\x82"
    self.security_level= secure_context.level if secure_context.level
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
        self.p1= 0x03
      when :mac
        self.p1= 0x01
      when :no_sec
        self.p1= 0x00
      else
        self.p1=level  
    end
    @secure_context.level= level
  end
  
  # 
  # Sets the host cryptogram according to CPS 3.2.6.6
  #
  def cryptogram 
    @cryptogram ||= secure_context.calculate_host_cryptogram
    @cryptogram
  end

  # Explicitly set a cryptogram, e.g. if an incorrect cryptogram is to be set
  # for testing.
  def cryptogram= bytes 
    @cryptogram= bytes
  end

    
  def send handle_more_data=true, card=nil
    @data=  self.cryptogram
    @data+= c_mac # calculate the c_mac...
    super
  end


end
class STORE_DATA < C_MAC_APDU 

  LAST_STORE_DATA_MASK = 0x80
  ALL_DGI_ENC_MASK =     0x60
  NO_DGI_ENC_MASK =      0x00
  APP_DEPENDANT_MASK =   0x20

  SECURE_MASK = 0x04

  attr_reader :security_level

  def initialize card, secure_context, data=""
    super(card, secure_context)
    @ins= "\xE2"
    #@security_level = secure_context.level
    @cla= "\x84" if @security_level == :enc_and_mac
    self.data= data
  end
  def security_level= level
    @security_level = level
    if level == :enc_and_mac
      secure
    else
      self.cla = 0x80
    end   
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
  
  def send handle_more_data=true, card=nil

    @p2 = secure_context.store_data_seq_number

    # Secure Ctx security level may change in the course of a series of
    # apdus, so we only no the current state just before sending.
    @security_level ||= @secure_context.level

    unless @security_level == :no_sec
      c_mac_ = self.c_mac # c_mac  is calculated over unencrypted data
      if @security_level == :enc_and_mac
        @data= secure_context.encrypt(self.data)+c_mac_
      else
        @data= self.data+c_mac_
      end
    end
    super
  end

end

end #CPS
end # APDU
end #EMV
