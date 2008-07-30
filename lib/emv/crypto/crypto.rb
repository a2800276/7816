module EMV
module Crypto
  
  # Generate Session keys according to CPS 5.3 
  def self.generate_session_key ic_card_key, seq, type
    seq         = check_and_convert("seq", seq, 2)
    ic_card_key = check_and_convert("ic_card_key", ic_card_key, 16)
    
    derivation_data = case type
            when :enc
              "\x01\x82"
            when :mac
              "\x01\x01"
            when :dek
              "\x01\x81"
            else
              raise "invalid type of key: #{type}"
            end

    derivation_data += seq + ISO7816.s2b("000000000000000000000000")

    cipher = OpenSSL::Cipher::Cipher.new("des-ede-cbc").encrypt
    cipher.key = ic_card_key
    cipher.update derivation_data
  end
  
  # Mac calculation according to CPS 5.4.1. 
  def self.mac_for_personalization key, input
    key = check_and_convert "key", key, 16

    input += "\x80"
    while (input.length % 8) != 0
      input << 0x00
    end
    cipher = OpenSSL::Cipher::Cipher.new("des-ede-cbc").encrypt
    cipher.key = key
    mac = ""
    input.scan(/.{8}/) {|block|
      mac = cipher.update block
    }
    mac
  end

  def self.check_and_convert mes, data, length_in_bytes
    unless data.length == length_in_bytes || data.length == length_in_bytes*2
      raise "invalid length for '#{mes}'. Should be #{length_in_bytes}" 
    end
    data = ISO7816.s2b(data) if data.length == length_in_bytes*2
    data
  end

end #module Crypto
end #module EMV
